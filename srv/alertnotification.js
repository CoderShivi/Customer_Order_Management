const xsenv = require('@sap/xsenv');
xsenv.loadEnv();

const services = xsenv.getServices({
    alertNotification: {
        tag: 'alert-notification'
    }
});

const credentials = services.alertNotification;

async function sendAlert(eventType, subject, body) {

    try {
        // Generate OAuth Token
        const tokenResponse = await fetch(
            `${credentials.uaa.url}/oauth/token?grant_type=client_credentials`,
            {
                method: 'POST',

                headers: {
                    Authorization:
                        'Basic ' +
                        Buffer.from(
                            `${credentials.uaa.clientid}:${credentials.uaa.clientsecret}`
                        ).toString('base64')
                }
            }
        );

        const tokenData = await tokenResponse.json();

        // Send Alert Event
        await fetch(credentials.url, {

            method: 'POST',

            headers: {
                Authorization: `Bearer ${tokenData.access_token}`,
                'Content-Type': 'application/json'
            },

            body: JSON.stringify({
                eventType,
                subject,
                body
            })
        });

        console.log('Alert notification sent');

    } catch (error) {

        console.error('Alert notification failed:', error);

    }
}

module.exports = {
    sendAlert
};