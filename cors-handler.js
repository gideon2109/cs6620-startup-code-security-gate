exports.handler = async (event) => {
  // Handle OPTIONS (CORS preflight)
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'content-type, application/json',
      },
      body: '',
    };
  }
  
  // Forward POST requests to your main Lambda
  // (This is just for CORS, you can also call your main Lambda)
  return {
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
    },
    body: JSON.stringify({ message: 'CORS preflight successful' }),
  };
};
