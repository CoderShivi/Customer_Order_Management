namespace order.db;
using {cuid, managed} from '@sap/cds/common';
type OrderStatus : String enum {
     PROCESSING;
     SHIPPED;
     DELIVERED;
     CANCELLED;
     DRAFT;
     NEW;
}

type InvoiceStatus : String enum {
    DRAFT;
    GENERATED;
    PAID;
    OVERDUE;
    CANCELLED;
}

type PaymentStatus : String enum {
    PENDING;
    PARTIAL;
    PAID;
    FAILED;
    REFUNDED;
    CANCELLED;
}

type PaymentMethod : String enum {
    CASH;
    CREDIT_CARD;
    DEBIT_CARD;
    UPI;
    NET_BANKING;
    WALLET;
}

type AddressType : String enum {
    BILLING;
    SHIPPING;
}

entity Customers : cuid, managed {
    CustomerCode    : String(20);
    Name            : String(100);
    Email           : String(120);
    Phone           : String(20); 
    CreditLimit     : Decimal(15,2);
    Orders          : Association to many SalesOrders
                        on Orders.Customer = $self;
    Addresses : Composition of many Addresses
                on Addresses.Customer = $self;   
    status:String enum{
        Available;
        NotAvailable;  
    }                             
}


entity Products     : cuid, managed {
    ProductCode     : String(20);
    Name            : String(120);
    Description     : String(255);
    UnitPrice       : Decimal(15,2);
    TaxRate         : Decimal(5,2);
    StockQty        : Integer;
    OrderItems      : Association to many OrderItems
                        on OrderItems.Product = $self;
}

entity SalesOrders  : cuid, managed {
    Customer        : Association to Customers;
    OrderDate       : Date;
    Status          : OrderStatus default 'DRAFT';
    TotalAmount     : Decimal(15,2);
    ShippingAddress : String(255);
    Items           : Composition of many OrderItems
                        on Items.Order = $self;
}

entity OrderItems   : cuid, managed {
    Order           : Association to SalesOrders;
    Product         : Association to Products;
    Quantity        : Integer;
    UnitPrice       : Decimal(15,2);
    Discount        : Decimal(5,2) default 0;
    LineTotal       : Decimal(15,2);
}

entity Invoices : cuid, managed {
    SalesOrder      : Association to one SalesOrders;
    InvoiceDate     : Date;
    DueDate         : Date;
    TotalAmount     : Decimal(15,2);
    TaxAmount       : Decimal(15,2);
    Status          : InvoiceStatus default 'DRAFT';
    PaidOn          : Date;
    Payments : Association to many Payments
              on Payments.Invoice = $self;
}

entity Payments : cuid, managed {
    Invoice          : Association to Invoices;
    PaymentDate      : Date;
    Amount           : Decimal(15,2);
    PaymentMethod    : PaymentMethod;
    TransactionID    : String(100);
    Status           : PaymentStatus default 'PENDING'
}

entity Addresses : cuid, managed {
    AddressLine1 : String(120);
    AddressLine2 : String(120);
    City         : String(50);
    State        : String(50);
    Country      : String(50);
    PostalCode   : String(20);
    AddressType  : String(20);
    Customer     : Association to Customers;
}

entity UniqueOrderStatuses as
        select from SalesOrders {
            key Status
        }
        group by Status;

entity UniqueinvoiceStatuses as
        select from Invoices {
            key Status
        }
        group by Status;


