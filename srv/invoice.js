const cds = require('@sap/cds');

module.exports = cds.service.impl(async function () {
    const { Invoices } = this.entities;
   
  this.on('markAsPaid', async (req) => {

        const invoiceID = req.params[0].ID;
        const invoice = await SELECT.one
            .from(Invoices)
            .where({
                ID: invoiceID
            });

        if (!invoice) {
            req.error(404, 'Invoice not found');
        }

        if (invoice.Status === 'PAID') {
            req.error(
                400,
                'Invoice already paid'
            );
        }

        await UPDATE(Invoices)
            .set({
                Status: 'PAID',
                PaidOn: new Date()
            })
            .where({
                ID: invoiceID
            });

        return 'Invoice marked as paid';
    });

    this.on('getOverdueInvoices', async (req) => {
        const { daysOverdue } = req.data;
        const currentDate = new Date();
        const overdueDate = new Date();
        overdueDate.setDate(currentDate.getDate() - daysOverdue);
        const invoices = await SELECT.from(Invoices)
            .where({
                DueDate: { '<': overdueDate.toISOString().split('T')[0] },
                Status: { '!=': 'PAID' }
            });

        return invoices;
    });

});