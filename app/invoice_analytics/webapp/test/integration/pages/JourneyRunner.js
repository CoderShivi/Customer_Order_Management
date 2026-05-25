sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"invoiceanalytics/test/integration/pages/InvoiceAnalyticsList",
	"invoiceanalytics/test/integration/pages/InvoiceAnalyticsObjectPage"
], function (JourneyRunner, InvoiceAnalyticsList, InvoiceAnalyticsObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('invoiceanalytics') + '/test/flp.html#app-preview',
        pages: {
			onTheInvoiceAnalyticsList: InvoiceAnalyticsList,
			onTheInvoiceAnalyticsObjectPage: InvoiceAnalyticsObjectPage
        },
        async: true
    });

    return runner;
});

