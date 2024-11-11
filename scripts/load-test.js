import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Trend, Rate, Counter } from 'k6/metrics';

// Define custom metrics for tracking performance
const response_time_ms = new Trend('response_time_ms');
const error_rate = new Rate('error_rate');
const request_count = new Counter('request_count');
const success_rate = new Rate('success_rate');
const memory_usage = new Trend('memory_usage');
const cpu_usage = new Trend('cpu_usage');
const error_count = new Counter('error_count');
const stability_check = new Trend('stability_check');

// Retrieve environment variables for API Token and Org Name
const apiToken = __ENV.API_TOKEN;
const orgName = __ENV.ORG_NAME;

// Test options (stages represent ramp-up and ramp-down in load testing)
export let options = {
    stages: [
        { duration: '1m', target: 50 }, // ramp-up to 50 users
        { duration: '3m', target: 50 }, // maintain 50 users
        { duration: '1m', target: 0 },  // ramp-down to 0 users
    ],
    thresholds: {
        'response_time_ms': ['p(90)<500', 'p(95)<700'], // SLA for response times
        'error_rate': ['rate<0.05'], // Ensure less than 5% of errors
        'success_rate': ['rate>0.95'], // Ensure more than 95% success rate
        'http_req_duration': ['p(90)<500', 'p(95)<700'], // Response time SLA
        'error_count': ['count<5'], // Less than 5 errors
    },
};

export default function () {
    group('Load Test - Get Knowledge Base API', () => {
        // Construct the URL dynamically using orgName environment variable
        const url = 'https://solutionapi-qa.7targets.com/chatbot/gam/knowledge_base/df96b3de-979c-4fa8-85dc-8f981fb14683';
        
        const params = {
            headers: {
                'Content-Type': 'application/json',
            },
        };

        const res = http.get(url, params);
        request_count.add(1);

        // Track response time
        response_time_ms.add(res.timings.duration);

        // Check response status and track errors
        const isSuccess = check(res, {
            'status is 200': (r) => r.status === 200,
            'response time below 500ms': (r) => r.timings.duration < 500,
        });

        success_rate.add(isSuccess);
        if (!isSuccess) {
            error_rate.add(1);
            error_count.add(1); // Increment error count for each failure
        } else {
            error_rate.add(0); // No errors for successful requests
        }

        // Track stability and reliability of the application
        stability_check.add(res.timings.duration);

        // Example: Track CPU and memory usage (these would come from system monitoring tools, mocked here)
        const cpu_usage_metric = Math.random() * 100; // Replace with real CPU usage value
        const memory_usage_metric = Math.random() * 1024; // Replace with real memory usage value

        cpu_usage.add(cpu_usage_metric);
        memory_usage.add(memory_usage_metric);

        // Add sleep to simulate real user interactions
        sleep(1);
        console.log(`API Token: ${apiToken}`);
        console.log(`Org Name: ${orgName}`);
    });
}