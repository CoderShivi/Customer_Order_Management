const cds = require('@sap/cds');

module.exports = cds.service.impl(async function () {
    const { Payments, Invoices } = this.entities;
    // Make Payment
    this.on('makePayment', async (req) => {
        const {
            invoiceID,
            amount,
            paymentMethod
        } = req.data;

        const invoice = await SELECT.one.from(Invoices)
            .where({ ID: invoiceID });

        if (!invoice) {
            req.error(404, 'Invoice not found');
        }

        if (invoice.Status === 'PAID') {
            req.error(400, 'Invoice already paid');
        }
        await INSERT.into(Payments).entries({
            Invoice_ID: invoiceID,
            PaymentDate: new Date(),
            Amount: amount,
            PaymentMethod: paymentMethod,
            TransactionID: cds.utils.uuid(),
            Status: 'PAID'
        });

        await UPDATE(Invoices)
            .set({
                Status: 'PAID',
                PaidOn: new Date()
            })
            .where({ ID: invoiceID });

        return 'Payment completed successfully';
    });

    //Refund Payment
    this.on('refundPayment', async (req) => {
        const { paymentID, reason } = req.data;
        const payment = await SELECT.one.from(Payments)
            .where({ ID: paymentID });

        if (!payment) {
            req.error(404, 'Payment not found');
        }

        await UPDATE(Payments)
            .set({
                Status: 'REFUNDED'
            })
            .where({ ID: paymentID });

        console.log('Refund Reason:', reason);

        return 'Payment refunded successfully';
    });

    //Verify Payment
    this.on('verifyPayment', async (req) => {
        const { paymentID } = req.data;
        const payment = await SELECT.one.from(Payments)
            .where({ ID: paymentID });

        if (!payment) {
            req.error(404, 'Payment not found');
        }

        return payment.Status === 'PAID';
    });

    // Get Pending Payments
    this.on('getPendingPayments', async () => {
        return await SELECT.from(Payments)
            .where({
                Status: 'PENDING'
            });
    });

    //Get Total Payments
    this.on('getTotalPayments', async () => {
        const result = await SELECT.one
            .from(Payments)
            .columns('sum(Amount) as total')
            .where({
                Status: 'PAID'
            });
        return result.total || 0;
    });

    //Get Payments By Date Range
    this.on('getPaymentsByDateRange', async (req) => {

        const { fromDate, toDate } = req.data;

        return await SELECT.from(Payments)
            .where({
                PaymentDate: {
                    '>=': fromDate,
                    '<=': toDate
                }
            });
    });

});