using OrderService as service from '../../srv/service';
annotate service.Products with @(
    UI.FieldGroup #GeneratedGroup : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Label : 'ProductCode',
                Value : ProductCode,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Name',
                Value : Name,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Description',
                Value : Description,
            },
            {
                $Type : 'UI.DataField',
                Label : 'UnitPrice',
                Value : UnitPrice,
            },
            {
                $Type : 'UI.DataField',
                Label : 'TaxRate',
                Value : TaxRate,
            },
            {
                $Type : 'UI.DataField',
                Label : 'StockQty',
                Value : StockQty,
            },
        ],
    },
    UI.Facets : [
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet1',
            Label : 'General Information',
            Target : '@UI.FieldGroup#GeneratedGroup',
        },
    ],
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'ProductCode',
            Value : ProductCode,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Name',
            Value : Name,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Description',
            Value : Description,
        },
        {
            $Type : 'UI.DataField',
            Label : 'UnitPrice',
            Value : UnitPrice,
        },
        {
            $Type : 'UI.DataField',
            Label : 'TaxRate',
            Value : TaxRate,
        },
    ],
);

