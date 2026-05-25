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
  entity SalesOrders as projection on db.SalesOrders

    actions {

      @requires               : [
        'SalesManager',
        'Administrator'
      ]
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

      @requires               : [
        'SalesManager',
        'Administrator'
      ]

      @Core.OperationAvailable: {$edmJson: {$Eq: [
        {$Path: 'Status'},
        'PROCESSING'
      ]}}
      action shipOrder()       returns String;

      @requires               : [
        'SalesManager',
        'Administrator'
      ]
      @Core.OperationAvailable: {$edmJson: {$Eq: [
        {$Path: 'Status'},
        'SHIPPED'
      ]}}

      action deliverOrder()              returns String;

      @requires               : [
        'SalesManager',
        'Administrator'
      ]
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
      action markAsPaid() returns String;
    };

  @requires: [
    'Finance',
    'SalesManager',
    'Administrator'
  ]
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

  @requires: [
    'SalesManager',
    'Administrator'
  ]
  action   makePayment(invoiceID: UUID, amount: Decimal(15, 2), paymentMethod: String) returns String;

  @requires: [
    'SalesManager',
    'Administrator'
  ]
  action   refundPayment(paymentID: UUID, reason: String)                              returns String;

  @requires: [
    'SalesManager',
    'Administrator'
  ]
  action   verifyPayment(paymentID: UUID)                                              returns Boolean;

  @requires: [
    'SalesManager',
    'Administrator'
  ]
  function getPendingPayments()                                                        returns array of Payments;

  @requires: [
    'SalesManager',
    'Administrator'
  ]
  function getTotalPayments()                                                          returns Decimal(15, 2);

  @requires: [
    'SalesManager',
    'Administrator'
  ]
  function getPaymentsByDateRange(fromDate: Date, toDate: Date)                        returns array of Payments;
}
