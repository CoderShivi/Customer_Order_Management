const xsenv = require('@sap/xsenv');
const {
  AlertNotificationClient,
  OAuthAuthentication,
  RegionUtils
} = require('@sap_oss/alert-notification-client');

xsenv.loadEnv();

const services = xsenv.getServices({
  ans: { name: 'alert-notification' }
});

console.log('Alert Notification Credentials:', services.ans);

console.log('Alert Notification Credentials:');
console.log(JSON.stringify(services.ans, null, 2));

const tokenUrl =
  services.ans.oauth_url ||
  services.ans.token_url;



if (!tokenUrl) {
  throw new Error(
    'OAuth URL not found in Alert Notification service credentials'
  );
}

const client = new AlertNotificationClient({
  authentication: new OAuthAuthentication({
    username: services.ans.client_id,
    password: services.ans.client_secret,
    oAuthTokenUrl: tokenUrl.split('?')[0]
  }),
  uri: services.ans.url,
  region: RegionUtils.US10
});

async function sendAlert(message, type) {
  const event = {
    resource: {
      resourceName: 'OrderService',
      resourceType: 'CAP_APP'
    },
    eventType: 'CustomAlert',
    subject: `Order ${type}`,
    body: message,
    severity: 'INFO',
    category: 'NOTIFICATION'
  };

  try {
    console.log('Sending Event:', JSON.stringify(event, null, 2));

    const response = await client.sendEvent(event);

    console.log('Alert sent successfully');
    return response;
  } catch (err) {
    console.error(
      'Alert failed:',
      JSON.stringify(err.response?.data || err, null, 2)
    );
  }
}

module.exports = { sendAlert };