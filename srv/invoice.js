const cds = require('@sap/cds');

const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

module.exports = cds.service.impl(async function () {
    const { Invoices } = this.entities;
   
 this.on('markAsPaid', async (req) => {

    const invoiceID = req.params[0].ID;

    // Fetch invoice
    const invoice = await SELECT.one
        .from(Invoices)
        .where({
            ID: invoiceID
        });

    // Invoice validation
    if (!invoice) {

        req.error(
            404,
            'Invoice not found'
        );
    }

    // Already paid validation
    if (invoice.Status === 'PAID') {

        req.error(
            400,
            'Invoice already paid'
        );
    }

    // Cancelled validation
    if (invoice.Status === 'CANCELLED') {

        req.error(
            400,
            'Cancelled invoice cannot be paid'
        );
    }

    // Update invoice
    await UPDATE(Invoices)
        .set({
            Status : 'PAID',
            PaidOn : new Date()
        })
        .where({
            ID : invoiceID
        });

    return 'Invoice marked as paid successfully';
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

    this.on('cancelInvoice', async (req) => {
    const invoiceID = req.params[0].ID;
    const {reason} = req.data;
    
    const invoice = await SELECT.one
        .from(Invoices)
        .where({
            ID: invoiceID
        });
    if (!invoice) {

        req.error(
            404,
            'Invoice not found'
        );
    }

    if (invoice.Status === 'CANCELLED') {

        req.error(
            400,
            'Invoice already cancelled'
        );
    }

    if (invoice.Status === 'PAID') {

        req.error(
            400,
            'Paid invoice cannot be cancelled'
        );
    }

    await UPDATE(Invoices)
        .set({
            Status : 'CANCELLED'
        })
        .where({
            ID : invoiceID
        });

    console.log(
        'Invoice Cancellation Reason:',
        reason
    );

    return 'Invoice cancelled successfully';
});

// this.on('downloadInvoicePDF', async (req) => {

//     const invoiceID = req.params[0].ID;
//     const invoice = await SELECT.one
//         .from(Invoices)
//         .where({
//             ID: invoiceID
//         });


//     if (!invoice) {

//         req.error(
//             404,
//             'Invoice not found'
//         );
//     }

//     if (
//         invoice.Status !== 'GENERATED' &&
//         invoice.Status !== 'PAID' &&
//         invoice.Status !== 'OVERDUE'
//     ) {

//         req.error(
//             400,
//             `Cannot download invoice when status is ${invoice.Status}`
//         );
//     }

//     const doc = new PDFDocument();

//     const filePath = path.join(
//         __dirname,
//         `Invoice-${invoiceID}.pdf`
//     );

//     doc.pipe(
//         fs.createWriteStream(filePath)
//     );

//     doc
//         .fontSize(22)
//         .text(
//             'INVOICE',
//             {
//                 align: 'center'
//             }
//         );

//     doc.moveDown();

//     doc
//         .fontSize(12)
//         .text(`Invoice ID : ${invoice.ID}`);

//     doc.text(
//         `Invoice Date : ${invoice.InvoiceDate}`
//     );

//     doc.text(
//         `Due Date : ${invoice.DueDate}`
//     );

//     doc.text(
//         `Status : ${invoice.Status}`
//     );

//     doc.text(
//         `Total Amount : ₹${invoice.TotalAmount}`
//     );

//     doc.text(
//         `Tax Amount : ₹${invoice.TaxAmount}`
//     );

//     doc.text(
//         `Paid On : ${invoice.PaidOn || 'N/A'}`
//     );

//     doc.moveDown();

//     doc.text(
//         'Thank you for your business.'
//     );

//     doc.end();

//     return `
//         Invoice PDF generated successfully:
//         ${filePath}
//     `;
// });
});