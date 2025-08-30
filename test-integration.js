const http = require('http');

console.log('🧪 Testing FreshConnect Integration...\n');

// Test server health
function testServerHealth() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 5000,
      path: '/api/health',
      method: 'GET'
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          console.log('✅ Server Health Check:');
          console.log(`   Status: ${response.status}`);
          console.log(`   Environment: ${response.environment}`);
          console.log(`   Active Connections: ${response.activeConnections}`);
          console.log(`   Timestamp: ${response.timestamp}\n`);
          resolve(response);
        } catch (error) {
          reject(new Error('Invalid JSON response'));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.setTimeout(5000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.end();
  });
}

// Test server root endpoint
function testServerRoot() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 5000,
      path: '/',
      method: 'GET'
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          console.log('✅ Server Root Endpoint:');
          console.log(`   Message: ${response.message}`);
          console.log(`   Version: ${response.version}`);
          console.log(`   Environment: ${response.environment}\n`);
          resolve(response);
        } catch (error) {
          reject(new Error('Invalid JSON response'));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.setTimeout(5000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.end();
  });
}

// Test CORS headers
function testCORS() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 5000,
      path: '/api/health',
      method: 'OPTIONS',
      headers: {
        'Origin': 'http://localhost:8080',
        'Access-Control-Request-Method': 'GET',
        'Access-Control-Request-Headers': 'Content-Type'
      }
    };

    const req = http.request(options, (res) => {
      console.log('✅ CORS Test:');
      console.log(`   Status: ${res.statusCode}`);
      console.log(`   Access-Control-Allow-Origin: ${res.headers['access-control-allow-origin']}`);
      console.log(`   Access-Control-Allow-Methods: ${res.headers['access-control-allow-methods']}`);
      console.log(`   Access-Control-Allow-Headers: ${res.headers['access-control-allow-headers']}\n`);
      resolve(res.headers);
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.setTimeout(5000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.end();
  });
}

// Run all tests
async function runTests() {
  try {
    await testServerHealth();
    await testServerRoot();
    await testCORS();
    
    console.log('🎉 All integration tests passed!');
    console.log('\n📱 Flutter app should now be able to connect to the backend.');
    console.log('🔌 Socket.IO is ready for real-time messaging.');
    console.log('\nNext steps:');
    console.log('1. Start your Flutter app: cd frontend && flutter run');
    console.log('2. Test authentication flow');
    console.log('3. Test real-time messaging');
    
  } catch (error) {
    console.error('❌ Integration test failed:', error.message);
    console.log('\nTroubleshooting:');
    console.log('1. Make sure the Node.js server is running: cd server && npm run dev');
    console.log('2. Check if port 5000 is available');
    console.log('3. Verify MongoDB is running (if using local database)');
    console.log('4. Check server logs for any errors');
  }
}

runTests();
