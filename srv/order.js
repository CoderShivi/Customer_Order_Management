const cds = require('@sap/cds');
const { UPDATE } = require('@sap/cds/lib/ql/cds-ql');

module.exports = cds.service.impl(async function () {
    const { SalesOrders, Products, OrderItems, Customers,  Addresses } = this.entities('OrderService');
    const {Invoices} = this.entities('InvoiceService');

this.before('SAVE', 'SalesOrders', async (req) => {

    const order = req.data;

    // Skip empty draft saves
    if (!order.Customer_ID) {
        return;
    }

    // Fetch shipping address
    const shippingAddress = await SELECT.one
        .from(Addresses)
        .where({
            Customer_ID: order.Customer_ID,
            AddressType: 'SHIPPING'
        });

        console.log(shippingAddress);

    // Validation
   /*if (!shippingAddress) {

        req.error(
            400,
            'Shipping address not found for customer'
        );
    }
    

    // Store snapshot
    order.ShippingAddress =
        `${shippingAddress.AddressLine1}, ${shippingAddress.City}, ${shippingAddress.State}, ${shippingAddress.Country}`;**/
});



this.before(['CREATE', 'PATCH'], 'OrderItems.drafts', async (req) => {

    const existing = await SELECT.one
        .from('OrderService.OrderItems.drafts')
        .where({ ID: req.data.ID });

    const salesOrder_ID =
        req.data.Order_ID ??
        existing?.Order_ID;

    if (!salesOrder_ID) return;

    const order = await SELECT.one
        .from('OrderService.SalesOrders.drafts')
        .where({ ID: salesOrder_ID });

    if (!order) {
        return req.error(404, 'Sales order not found');
    }


    const product_ID =
        req.data.Product_ID ??
        existing?.Product_ID;

    const quantity =
        req.data.Quantity ??
        existing?.Quantity ??
        0;

    const discount =
        req.data.Discount ??
        existing?.Discount ??
        0;

    if (!product_ID) return;

    const product = await SELECT.one
        .from(Products)
        .where({ ID: product_ID });

    if (!product) {
        return req.error(404, 'Product not found');
    }

    req.data.UnitPrice = product.UnitPrice;

    const lineTotal =
        (quantity * product.UnitPrice) - discount;

    req.data.LineTotal =
        Number(lineTotal.toFixed(2));

    const items = await SELECT
        .from('OrderService.OrderItems.drafts')
        .where({ Order_ID: salesOrder_ID });

   let totalAmount = 0;

for (const item of items) {

    if (item.ID === req.data.ID) continue;

    totalAmount += Number(item.LineTotal || 0);
}

totalAmount += Number(req.data.LineTotal || 0);

await UPDATE('OrderService.SalesOrders.drafts')
    .set({
        TotalAmount: Number(totalAmount.toFixed(2))
    })
    .where({ ID: salesOrder_ID });

        if (
        order.Status === 'SHIPPED' ||
        order.Status === 'DELIVERED' ||
        order.Status === 'CANCELLED'
    ) {

        return req.error(
            400,
            `Order items cannot be modified when order status is ${order.Status}`
        );
    }

});

this.before('DELETE', 'OrderItems.drafts', async (req) => {

    const existing = await SELECT.one.from(OrderItems.drafts).where({ ID: req.data.ID });

    if (!existing?.Order_ID) return;

    const items = await SELECT
        .from(OrderItems.drafts)
        .where({ Order_ID: existing.Order_ID });

    let totalAmount = 0;

    for (const item of items) {
        if (item.ID === existing.ID) continue;
        totalAmount += item.LineTotal || 0;
    }

    await UPDATE(SalesOrders.drafts)
        .set({
            TotalAmount: Number(totalAmount.toFixed(2))
        })
        .where({ ID: existing.Order_ID });
});

this.before('confirmOrder', async (req) => {

    const { ID, IsActiveEntity } = req.params[0];

    // Handle draft and active entities
    const OrderEntity = IsActiveEntity
        ? SalesOrders
        : SalesOrders.drafts;

    const ItemEntity = IsActiveEntity
        ? OrderItems
        : OrderItems.drafts;

    // Fetch order
    const order = await SELECT.one
        .from(OrderEntity)
        .where({ ID });

    if (!order) {
        return req.error(404, 'Order not found');
    }

    // Status validations
    if (order.Status === 'CANCELLED') {

        return req.error(
            400,
            'Cancelled order cannot be confirmed'
        );
    }

    if (
        order.Status === 'PROCESSING' ||
        order.Status === 'SHIPPED' ||
        order.Status === 'DELIVERED'
    ) {

        return req.error(
            400,
            `Order already ${order.Status}`
        );
    }

    // Fetch customer
    const customer = await SELECT.one
        .from(Customers)
        .where({
            ID: order.Customer_ID
        });

    if (!customer) {

        return req.error(
            404,
            'Customer not found'
        );
    }

    // Credit limit validation
    if (
        order.TotalAmount >
        customer.CreditLimit
    ) {

        return req.error(
            400,
            'Order amount exceeds customer credit limit'
        );
    }

    // Fetch items
    const items = await SELECT
        .from(ItemEntity)
        .where({
            Order_ID: ID
        });

    if (!items.length) {

        return req.error(
            400,
            'Order must contain at least one item'
        );
    }

    // Stock validation
    for (const item of items) {

        const product = await SELECT.one
            .from(Products)
            .where({
                ID: item.Product_ID
            });

        if (!product) {

            return req.error(
                404,
                `Product not found for item ${item.ID}`
            );
        }

        if (
            product.StockQty <
            item.Quantity
        ) {

            return req.error(
                400,
                `Insufficient stock for ${product.Name}`
            );
        }
    }
});

this.on('confirmOrder', async (req) => {

    const orderID = req.params[0].ID;

    // Fetch items
    const items = await SELECT
        .from(OrderItems)
        .where({
            Order_ID: orderID
        });

    // Reduce stock
    for (const item of items) {

        const product = await SELECT.one
            .from(Products)
            .where({
                ID: item.Product_ID
            });

        await UPDATE(Products)
            .set({
                StockQty:
                    product.StockQty -
                    item.Quantity
            })
            .where({
                ID: item.Product_ID
            });
    }

    // Update status
    await UPDATE(SalesOrders)
        .set({
            Status: 'PROCESSING'
        })
        .where({
            ID: orderID
        });

    return 'Order confirmed successfully';
});


//
// SHIP ORDER
//
this.on('shipOrder', async (req) => {

    const orderID = req.params[0].ID;

    // Fetch order
    const order = await SELECT.one
        .from(SalesOrders)
        .where({
            ID: orderID
        });

    if (!order) {
        req.error(404, 'Order not found');
    }

    // Validation
    if (order.Status === 'CANCELLED') {

        req.error(
            400,
            'Cancelled order cannot be shipped'
        );
    }

    if (order.Status !== 'PROCESSING') {

        req.error(
            400,
            'Only confirmed orders can be shipped'
        );
    }

    // Update status
    await UPDATE(SalesOrders)
        .set({
            Status: 'SHIPPED'
        })
        .where({
            ID: orderID
        });

    return 'Order shipped successfully';
});


//
// DELIVER ORDER
//
this.before('deliverOrder', async (req) => {

    const orderID = req.params[0].ID;

    const order = await SELECT.one
        .from(SalesOrders)
        .where({ ID: orderID });

    if (!order) {
        req.error(404, 'Order not found');
    }

    if (order.Status !== 'SHIPPED') {
        req.error(400, 'Only shipped orders can be delivered');
    }

    // attach to request so later handlers can reuse it
    req.data._order = order;
});


this.on('deliverOrder', async (req) => {

    const orderID = req.params[0].ID;

    await UPDATE(SalesOrders)
        .set({ Status: 'DELIVERED' })
        .where({ ID: orderID });

    return 'Order delivered successfully';
});

this.after('deliverOrder', async (data, req) => {
    const orderID = req.params[0].ID;
    console.log('Generating invoice for order', orderID);

    // Fetch order from DB
    const order = await SELECT.one
        .from(SalesOrders)
        .where({
            ID: orderID
        });

    if (!order) {

        req.error(
            404,
            'Order not found'
        );
    }

    // Prevent duplicate invoice
    const existingInvoice = await SELECT.one
        .from(Invoices)
        .where({
            SalesOrder_ID: orderID
        });

    if (existingInvoice) return;

    // Generate dates
    const today = new Date();

    const invoiceDate =
        today.toISOString().split('T')[0];

    const dueDate = new Date();

    dueDate.setDate(
        today.getDate() + 7
    );

    // Create invoice
    await INSERT.into(Invoices).entries({

        SalesOrder_ID: orderID,
        InvoiceDate: invoiceDate,
        DueDate:
        dueDate.toISOString().split('T')[0],
        TotalAmount: order.TotalAmount,
        TaxAmount: 0,
        Status: 'GENERATED'
    });

});
//
// CANCEL ORDER
//
this.on('cancelOrder', async (req) => {

    const orderID = req.params[0].ID;

    const {reason} = req.data;

    // Fetch order
    const order = await SELECT.one
        .from(SalesOrders)
        .where({
            ID: orderID
        });

    if (!order) {
        req.error(404, 'Order not found');
    }

    // Validation
    if (order.Status === 'DELIVERED') {

        req.error(
            400,
            'Delivered order cannot be cancelled'
        );
    }

    if (order.Status === 'CANCELLED') {

        req.error(
            400,
            'Order already cancelled'
        );
    }

    // Restore stock
    const items = await SELECT
        .from(OrderItems)
        .where({
            Order_ID: orderID
        });

    for (const item of items) {

        const product = await SELECT.one
            .from(Products)
            .where({
                ID: item.Product_ID
            });

        await UPDATE(Products)
            .set({
                StockQty:
                    product.StockQty +
                    item.Quantity
            })
            .where({
                ID: item.Product_ID
            });
    }

    // Update status
    await UPDATE(SalesOrders)
        .set({
            Status: 'CANCELLED'
        })
        .where({
            ID: orderID
        });

    console.log(
        'Cancellation Reason:',
        reason
    );

    return 'Order cancelled successfully';
});

});