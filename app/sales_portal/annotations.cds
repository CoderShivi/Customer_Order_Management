using OrderService as service from '../../srv/service';
annotate service.SalesOrders with @(
    UI.FieldGroup #GeneratedGroup : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {       
                $Type: 'UI.DataField',
                Label: 'OrderDate',
                Value: OrderDate,
            },
            {
                $Type: 'UI.DataField',
                Label: 'Customer',
                Value: Customer_ID,
            },
            {
                $Type       : 'UI.DataField',
                Label       : 'Status',
                Value       : Status,
                Criticality : (Status = 'SHIPPED' ? 5 : Status = 'CANCELLED' ? 1 : 3)
            },
            {
                $Type: 'UI.DataField',
                Label: 'TotalAmount',
                Value: TotalAmount,
            },
            {
                $Type: 'UI.DataField',
                Label: 'ShippingAddress',
                Value: ShippingAddress,
            }

        ],
    },
    UI.Facets                     : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'GeneratedFacet1',
            Label : 'Order Details',
            Target: '@UI.FieldGroup#GeneratedGroup',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Items',
            ID    : 'Items',
            Target: 'Items/@UI.LineItem#Items',
        },
    ],
    UI.LineItem                   : [
        {
            $Type: 'UI.DataField',
            Label: 'OrderDate',
            Value: OrderDate,
        },
        {
            $Type: 'UI.DataField',
            Label: 'Customer',
            Value: Customer_ID,
        },
        {
            $Type       : 'UI.DataField',
            Label       : 'Status',
            Value       : Status,
            Criticality : (Status = 'SHIPPED' ? 5 : Status = 'CANCELLED' ? 1 : 3)
        },
        {
            $Type: 'UI.DataField',
            Label: 'TotalAmount',
            Value: TotalAmount,
        },
        {
            $Type: 'UI.DataField',
            Label: 'ShippingAddress',
            Value: ShippingAddress,
        },
    ],


    UI.SelectionFields            : [
        Status,
        Customer_ID
    ],

    UI.Identification             : [
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'OrderService.confirmOrder',
            Label : 'Confirm Order',
            Criticality:3
        },

        {
            $Type : 'UI.DataFieldForAction',
            Action: 'OrderService.shipOrder',
            Label : 'Ship Order',
            Criticality:4

        },

        {
            $Type : 'UI.DataFieldForAction',
            Action: 'OrderService.deliverOrder',
            Label : 'Deliver Order'
        },

        {
            $Type : 'UI.DataFieldForAction',
            Action: 'OrderService.cancelOrder',
            Label : 'Cancel Order'
        }

    ]
);

annotate service.OrderItems with @(
    UI.LineItem : [
        {
            $Type: 'UI.DataField',
            Label: 'Product',
            Value: Product_ID,
        },
        {
            $Type: 'UI.DataField',
            Label: 'Quantity',
            Value: Quantity,
        },

        {
            $Type: 'UI.DataField',
            Label: 'Unit Price',
            Value: UnitPrice,
        },

        {
            $Type: 'UI.DataField',
            Label: 'Discount',
            Value: Discount,
        },

        {
            $Type: 'UI.DataField',
            Label: 'Line Total',
            Value: LineTotal,
        }
    ],

    UI.LineItem #Items: [
        {
            $Type: 'UI.DataField',
            Value: Product_ID,
            Label: 'Name',
        },
        {
            $Type: 'UI.DataField',
            Value: Quantity,
            Label: 'Quantity',
        },
        {
            $Type: 'UI.DataField',
            Value: UnitPrice,
            Label: 'UnitPrice',
        },
        {
            $Type: 'UI.DataField',
            Value: Discount,
            Label: 'Discount',
        },
    ],
);


annotate service.OrderItems with {
    Product @(
        Common.Text     : Product.Name,

        Common.ValueList: {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'Products',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: Product_ID,
                    ValueListProperty: 'ID'
                },

                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'ProductCode'
                },

                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'Name'
                }

            ]
        }
    );

};

annotate service.SalesOrders with {

    Customer @(
        Common.Text     : Customer.Name,
        Common.ValueList: {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'Customers',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: Customer_ID,
                    ValueListProperty: 'ID'
                },

                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'CustomerCode'
                },

                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'Name'
                }

            ]
        }
    );
};


annotate service.OrderItems with {
    UnitPrice @Common.FieldControl: #ReadOnly;
    LineTotal @Common.FieldControl: #ReadOnly;
};

annotate service.SalesOrders with {
    TotalAmount @Common.FieldControl: #ReadOnly;
};

annotate service.OrderItems with @Common.SideEffects #ProductChanged: {
    SourceProperties: [
        Product_ID,
        Quantity
    ],
    TargetProperties: [
        UnitPrice,
        LineTotal
    ]
};

annotate service.SalesOrders with @Common.SideEffects #ItemsChanged: {
    SourceEntities  : [Items],
    TargetProperties: [TotalAmount]
};

annotate OrderService.OrderItems with @(

    Capabilities.UpdateRestrictions: {Updatable: {$edmJson: {$Or: [

        {$Eq: [
            {$Path: 'Order/Status'},
            'NEW'
        ]},

        {$Eq: [
            {$Path: 'Order/Status'},
            'PROCESSING'
        ]},

        {$Eq: [
            {$Path: 'Order/Status'},
            'DRAFT'
        ]}

    ]}}},

    Capabilities.DeleteRestrictions: {Deletable: {$edmJson: {$Or: [
        {$Eq: [
            {$Path: 'Order/Status'},
            'NEW'
        ]},

        {$Eq: [
            {$Path: 'Order/Status'},
            'PROCESSING'
        ]},

        {$Eq: [
            {$Path: 'Order/Status'},
            'DRAFT'
        ]}

    ]}}}

);

annotate OrderService.SalesOrders with @(Capabilities.UpdateRestrictions: {Updatable: {$edmJson: {$Or: [
    {$Eq: [
        {$Path: 'Status'},
        'NEW'
    ]},

    {$Eq: [
        {$Path: 'Status'},
        'PROCESSING'
    ]},

    {$Eq: [
        {$Path: 'Status'},
        'DRAFT'
    ]}

]}}}
);

annotate service.SalesOrders with {
    Status @(
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'uniqueOrderStatuses',
            Parameters    : [{
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: Status,
                ValueListProperty: 'Status'
            }]
        },
        Common.ValueListWithFixedValues: true
    )
};

annotate OrderService.SalesOrders with @(
    UI.HeaderInfo : {
        TypeName       : 'Sales Order',
        TypeNamePlural : 'Sales Orders',    
        Title : {
            Value : ID
        },

        Description : {
            Value : Status
            
        }
    },

    UI.DataPoint #TotalAmount : {
        Title : 'Total Amount (₹)',
        Value : TotalAmount,
        Criticality : #Positive  
    },

    UI.HeaderFacets : [

        {
            $Type  : 'UI.ReferenceFacet',
            Label  : 'Order Amount',
            Target : '@UI.DataPoint#TotalAmount'
        }
    ]
);