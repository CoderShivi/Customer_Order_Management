using {order.db as db} from '../db/schema';

@requires: [
  'SalesRep',
  'SalesManager',
  'Finance',
  'Administrator'
]
@impl    : 'srv/order.js'
service OrderService {
  entity Customers   as projection on db.Customers;
  entity Addresses   as projection on db.Addresses;
  entity Products    as projection on db.Products;


  @restrict: [

    {
      grant: [
        'READ',
        'CREATE'
      ],
      to   : ['SalesRep']
    },
    {
      grant: [
        'READ',
        'CREATE',
        'UPDATE'
      ],
      to   : ['SalesManager']
    },
    {
      grant: '*',
      to   : ['Administrator']
    }
  ]

  @odata.draft.enabled
  @cds.redirection.target
  entity SalesOrders as projection on db.SalesOrders

    actions {
   @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'SalesManager']
    }]
      @Core.OperationAvailable: {$edmJson: {$Or: [
        {$Eq: [
          {$Path: 'Status'},
          'DRAFT'
        ]},
        {$Eq: [
          {$Path: 'Status'},
          'NEW'
        ]}
      ]}}

      action confirmOrder()      returns String;

       @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'SalesManager']
    }]

      @Core.OperationAvailable: {$edmJson: {$Eq: [
        {$Path: 'Status'},
        'PROCESSING'
      ]}}
      action shipOrder()       returns String;

      @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'SalesManager']
    }]
      @Core.OperationAvailable: {$edmJson: {$Eq: [
        {$Path: 'Status'},
        'SHIPPED'
      ]}}

      action deliverOrder()              returns String;

      @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'SalesManager']
    }]
      @Core.OperationAvailable: {$edmJson: {$Or: [
        {$Eq: [
          {$Path: 'Status'},
          'DRAFT'
        ]},
        {$Eq: [
          {$Path: 'Status'},
          'PROCESSING'
        ]}
      ]}}

      action cancelOrder(reason: String) returns String;
    };
    @restrict: [

    {
      grant: [
        'READ',
        'CREATE'
      ],
      to   : ['SalesRep']
    },
    {
      grant: [
        'READ',
        'CREATE',
        'UPDATE'
      ],
      to   : ['SalesManager']
    },
    {
      grant: '*',
      to   : ['Administrator']
    }
  ]

  entity OrderItems  as projection on db.OrderItems;

}


@impl: 'srv/invoice.js'
service InvoiceService {

  @restrict: [
    {
      grant: [
        'READ',
        'CREATE',
        'UPDATE'
      ],
      to   : ['Finance']
    },
    {
      grant: ['READ'],
      to   : ['SalesManager']
    },
    {
      grant: '*',
      to   : ['Administrator']
    }
  ]

  entity Invoices         as projection on db.Invoices
    actions {

       @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'Finance']
    }]
      @Core.OperationAvailable : {
    $edmJson : {
        $And : [

            {
                $Ne : [
                    { $Path : 'Status' },
                    'PAID'
                ]
            },

            {
                $Ne : [
                    { $Path : 'Status' },
                    'CANCELLED'
                ]
            }
        ]
    }
}
      action markAsPaid() returns String;

       @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'Finance']
    }]

      @Core.OperationAvailable : {
    $edmJson : {
        $And : [

            {
                $Ne : [
                    { $Path : 'Status' },
                    'PAID'
                ]
            },

            {
                $Ne : [
                    { $Path : 'Status' },
                    'CANCELLED'
                ]
            }
        ]
    }
}
      action cancelInvoice(reason : String) returns String;
          };
 @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'Finance']
    }]
  function getOverdueInvoices(daysOverdue: Integer)   returns array of Invoices;

  @Aggregation.ApplySupported                : {
    Transformations       : [
      'aggregate',
      'groupby',
      'filter',
      'top',
      'skip',
      'orderby'
    ],

    GroupableProperties   : [Status],

    AggregatableProperties: [
      {Property: totalAmount},
      {Property: overdueFlag}
    ]
  }

  @Analytics.AggregatedProperty #TotalRevenue: {
    Name                : 'TotalRevenue',
    AggregationMethod   : 'sum',
    AggregatableProperty: totalAmount,
    ![@Common.Label]    : 'Total Revenue'
  }

  @Analytics.AggregatedProperty #OverdueCount: {
    Name                : 'OverdueCount',
    AggregationMethod   : 'sum',
    AggregatableProperty: overdueFlag,
    ![@Common.Label]    : 'Overdue Count'
  }

  entity InvoiceAnalytics as
    select from db.Invoices {
      key Status,
          sum(TotalAmount) as totalAmount : Decimal(15, 2),
          sum(case
                when DueDate < CURRENT_DATE
                     and Status != 'PAID'
                     then 1
                else 0
              end)         as overdueFlag : Integer
    }
    group by
      Status;

}


@impl: 'srv/payment.js'
service PaymentService {
  @restrict: [
    {
      grant: [
        'READ',
        'CREATE',
        'UPDATE'
      ],
      to   : ['Finance']
    },
    {
      grant: ['READ'],
      to   : ['SalesManager']
    },
    {
      grant: '*',
      to   : ['Administrator']
    }
  ]
  entity Payments as projection on db.Payments;

  @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'SalesManager']
    }]
  action   makePayment(invoiceID: UUID, amount: Decimal(15, 2), paymentMethod: String) returns String;

  @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'SalesManager']
    }]
  action   refundPayment(paymentID: UUID, reason: String)                              returns String;

 @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'SalesManager']
    }]
  action   verifyPayment(paymentID: UUID)                                              returns Boolean;

  @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'SalesManager']
    }]
  function getPendingPayments()                                                        returns array of Payments;

  @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'SalesManager']
    }]
  function getTotalPayments()                                                          returns Decimal(15, 2);

  @restrict: [
      {
      grant: '*',
      to   : ['Administrator', 'SalesManager']
    }]
  function getPaymentsByDateRange(fromDate: Date, toDate: Date)                        returns array of Payments;
}
