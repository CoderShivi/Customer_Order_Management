using InvoiceService as service from '../../srv/service';
annotate service.Invoices with @(
    UI.FieldGroup #GeneratedGroup : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Label : 'InvoiceDate',
                Value : InvoiceDate,
            },
            {
                $Type : 'UI.DataField',
                Label : 'DueDate',
                Value : DueDate,
            },
            {
                $Type : 'UI.DataField',
                Label : 'TotalAmount',
                Value : TotalAmount,
            },
            {
                $Type : 'UI.DataField',
                Label : 'TaxAmount',
                Value : TaxAmount,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Status',
                Value : Status,
                Criticality : ( Status = 'DRAFT' ? 5 : Status = 'GENERATED' ? 3 : Status = 'PAID' ? 2 : 1)
            },
            {
                $Type : 'UI.DataField',
                Label : 'PaidOn',
                Value : PaidOn,
            },
        ],
    },
    UI.Facets : [
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet1',
            Label : 'Invoice Details',
            Target : '@UI.FieldGroup#GeneratedGroup',
        }
    ],
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'InvoiceDate',
            Value : InvoiceDate,
        },
        {
            $Type : 'UI.DataField',
            Label : 'DueDate',
            Value : DueDate,
        },
        {
            $Type : 'UI.DataField',
            Label : 'TotalAmount',
            Value : TotalAmount,
        },
        {
            $Type : 'UI.DataField',
            Label : 'TaxAmount',
            Value : TaxAmount,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Status',
            Value : Status,
           Criticality : ( Status = 'DRAFT' ? 5 : Status = 'GENERATED' ? 3 : Status = 'PAID' ? 2 : 1)
        },
        
    ],

      UI.HeaderInfo : {
        TypeName : 'Invoice',
        TypeNamePlural : 'Invoices',
        Title : {
            Value : ID
        }
    },

    // FILTER BAR
    UI.SelectionFields : [
        Status,
        DueDate
    ],
     UI.Identification : [
        {
            $Type : 'UI.DataFieldForAction',
            Action : 'InvoiceService.markAsPaid',
            Label : 'Mark As Paid'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action : 'InvoiceService.cancelInvoice',
            Label : 'Cancel Invoice'
        },
//         {
//     $Type  : 'UI.DataFieldForAction',
//     Action : 'InvoiceService.downloadInvoicePDF',
//     Label  : 'Download PDF'
// }
    ]
  
);

annotate service.Invoices with {
    Status @(
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'uniqueInvoiceStatuses',
            Parameters    : [{
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: Status,
                ValueListProperty: 'Status'
            }]
        },
        Common.ValueListWithFixedValues: true
    )
};

annotate service.Invoices with {

    DueDate @(
        Common.Text     : 'Due Date',
        Common.ValueList: {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'Invoices',
             Parameters    : [{
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: DueDate,
                ValueListProperty: 'DueDate'

            }]
            
            
        }
    );
};



