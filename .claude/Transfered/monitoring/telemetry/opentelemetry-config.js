/**
 * OpenTelemetry Configuration
 *
 * Complete observability setup with traces, metrics, and logs
 */

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');
const { PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');
const { BatchSpanProcessor } = require('@opentelemetry/sdk-trace-base');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');
const { PrometheusExporter } = require('@opentelemetry/exporter-prometheus');
const { diag, DiagConsoleLogger, DiagLogLevel } = require('@opentelemetry/api');

// Enable diagnostic logging for debugging
if (process.env.OTEL_LOG_LEVEL) {
  diag.setLogger(new DiagConsoleLogger(), DiagLogLevel[process.env.OTEL_LOG_LEVEL] || DiagLogLevel.INFO);
}

/**
 * Create OpenTelemetry SDK instance
 */
function createTelemetrySDK(config = {}) {
  const {
    serviceName = process.env.SERVICE_NAME || 'ai-orchestrator',
    serviceVersion = process.env.SERVICE_VERSION || '1.0.0',
    environment = process.env.NODE_ENV || 'development',
    enableTracing = true,
    enableMetrics = true,
    enableLogs = true,
    exporters = {
      traces: 'otlp', // 'otlp', 'jaeger', 'console'
      metrics: 'prometheus', // 'otlp', 'prometheus', 'console'
    }
  } = config;

  // Define resource attributes
  const resource = new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
    [SemanticResourceAttributes.SERVICE_VERSION]: serviceVersion,
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: environment,
    'service.namespace': 'ai-orchestrator',
    'service.instance.id': process.env.HOSTNAME || require('os').hostname(),
  });

  // Configure trace exporters
  const traceExporters = [];

  if (enableTracing) {
    switch (exporters.traces) {
      case 'otlp':
        traceExporters.push(
          new OTLPTraceExporter({
            url: process.env.OTEL_EXPORTER_OTLP_TRACES_ENDPOINT || 'http://localhost:4318/v1/traces',
            headers: {
              'Authorization': process.env.OTEL_EXPORTER_OTLP_HEADERS || ''
            }
          })
        );
        break;

      case 'jaeger':
        traceExporters.push(
          new JaegerExporter({
            endpoint: process.env.JAEGER_ENDPOINT || 'http://localhost:14268/api/traces',
          })
        );
        break;

      case 'console':
        const { ConsoleSpanExporter } = require('@opentelemetry/sdk-trace-base');
        traceExporters.push(new ConsoleSpanExporter());
        break;

      default:
        console.warn(`Unknown trace exporter: ${exporters.traces}`);
    }
  }

  // Configure metric exporters
  const metricReaders = [];

  if (enableMetrics) {
    switch (exporters.metrics) {
      case 'otlp':
        metricReaders.push(
          new PeriodicExportingMetricReader({
            exporter: new OTLPMetricExporter({
              url: process.env.OTEL_EXPORTER_OTLP_METRICS_ENDPOINT || 'http://localhost:4318/v1/metrics',
              headers: {
                'Authorization': process.env.OTEL_EXPORTER_OTLP_HEADERS || ''
              }
            }),
            exportIntervalMillis: 60000, // Export every 60 seconds
          })
        );
        break;

      case 'prometheus':
        const prometheusExporter = new PrometheusExporter({
          port: parseInt(process.env.PROMETHEUS_PORT || '9464'),
          endpoint: '/metrics',
        });
        metricReaders.push(prometheusExporter);
        console.log(`Prometheus metrics available at http://localhost:${process.env.PROMETHEUS_PORT || 9464}/metrics`);
        break;

      case 'console':
        const { ConsoleMetricExporter } = require('@opentelemetry/sdk-metrics');
        metricReaders.push(
          new PeriodicExportingMetricReader({
            exporter: new ConsoleMetricExporter(),
            exportIntervalMillis: 60000,
          })
        );
        break;

      default:
        console.warn(`Unknown metric exporter: ${exporters.metrics}`);
    }
  }

  // Configure span processors
  const spanProcessors = traceExporters.map(exporter =>
    new BatchSpanProcessor(exporter, {
      maxQueueSize: 2048,
      maxExportBatchSize: 512,
      scheduledDelayMillis: 5000,
      exportTimeoutMillis: 30000,
    })
  );

  // Create SDK instance
  const sdk = new NodeSDK({
    resource,
    spanProcessor: spanProcessors[0], // Primary span processor
    metricReader: metricReaders[0], // Primary metric reader
    instrumentations: [
      getNodeAutoInstrumentations({
        // Automatically instrument common libraries
        '@opentelemetry/instrumentation-http': {
          enabled: true,
          requestHook: (span, request) => {
            span.setAttribute('http.user_agent', request.headers['user-agent'] || 'unknown');
          },
          responseHook: (span, response) => {
            span.setAttribute('http.response.content_length', response.headers['content-length'] || 0);
          },
        },
        '@opentelemetry/instrumentation-express': {
          enabled: true,
          requestHook: (span, request) => {
            span.setAttribute('express.route', request.route?.path || 'unknown');
          },
        },
        '@opentelemetry/instrumentation-pg': {
          enabled: true,
          enhancedDatabaseReporting: true,
        },
        '@opentelemetry/instrumentation-redis': {
          enabled: true,
        },
        '@opentelemetry/instrumentation-mongodb': {
          enabled: true,
        },
        '@opentelemetry/instrumentation-fs': {
          enabled: false, // Can be noisy
        },
        '@opentelemetry/instrumentation-dns': {
          enabled: false, // Can be noisy
        },
      }),
    ],
  });

  return sdk;
}

/**
 * Initialize and start OpenTelemetry
 */
function initializeTelemetry(config) {
  const sdk = createTelemetrySDK(config);

  // Start the SDK
  sdk.start();

  console.log('OpenTelemetry initialized');

  // Graceful shutdown
  process.on('SIGTERM', () => {
    sdk.shutdown()
      .then(() => console.log('OpenTelemetry shut down successfully'))
      .catch((error) => console.error('Error shutting down OpenTelemetry', error))
      .finally(() => process.exit(0));
  });

  return sdk;
}

/**
 * Custom instrumentation helpers
 */
const { trace, metrics, context } = require('@opentelemetry/api');

// Get tracer
function getTracer(name = 'ai-orchestrator') {
  return trace.getTracer(name);
}

// Get meter
function getMeter(name = 'ai-orchestrator') {
  return metrics.getMeter(name);
}

// Create custom span
function createSpan(name, fn, options = {}) {
  const tracer = getTracer();

  return tracer.startActiveSpan(name, options, async (span) => {
    try {
      const result = await fn(span);
      span.setStatus({ code: 0 }); // OK
      return result;
    } catch (error) {
      span.setStatus({
        code: 2, // ERROR
        message: error.message,
      });
      span.recordException(error);
      throw error;
    } finally {
      span.end();
    }
  });
}

// Custom metrics
function createMetrics() {
  const meter = getMeter();

  return {
    // Counters
    agentCreationCounter: meter.createCounter('agent.creation.count', {
      description: 'Number of agents created',
      unit: '1',
    }),

    taskCompletionCounter: meter.createCounter('task.completion.count', {
      description: 'Number of tasks completed',
      unit: '1',
    }),

    errorCounter: meter.createCounter('errors.count', {
      description: 'Number of errors',
      unit: '1',
    }),

    // Histograms
    taskDurationHistogram: meter.createHistogram('task.duration', {
      description: 'Task execution duration',
      unit: 'ms',
    }),

    apiLatencyHistogram: meter.createHistogram('api.latency', {
      description: 'API endpoint latency',
      unit: 'ms',
    }),

    // Gauges (Observable)
    activeAgentsGauge: meter.createObservableGauge('agent.active.count', {
      description: 'Number of active agents',
      unit: '1',
    }),

    queueSizeGauge: meter.createObservableGauge('queue.size', {
      description: 'Number of tasks in queue',
      unit: '1',
    }),

    memoryUsageGauge: meter.createObservableGauge('memory.usage', {
      description: 'Memory usage in bytes',
      unit: 'bytes',
    }),
  };
}

/**
 * Middleware for automatic HTTP instrumentation
 */
function createTracingMiddleware() {
  return (req, res, next) => {
    const tracer = getTracer();

    tracer.startActiveSpan(`HTTP ${req.method} ${req.path}`, (span) => {
      // Add custom attributes
      span.setAttribute('http.method', req.method);
      span.setAttribute('http.url', req.url);
      span.setAttribute('http.route', req.route?.path || req.path);
      span.setAttribute('user.id', req.user?.id || 'anonymous');

      // Capture response
      const originalEnd = res.end;
      res.end = function(...args) {
        span.setAttribute('http.status_code', res.statusCode);
        span.setStatus({
          code: res.statusCode >= 400 ? 2 : 0,
        });
        span.end();
        originalEnd.apply(res, args);
      };

      next();
    });
  };
}

module.exports = {
  initializeTelemetry,
  createTelemetrySDK,
  getTracer,
  getMeter,
  createSpan,
  createMetrics,
  createTracingMiddleware,
};

/**
 * Usage Example:
 *
 * // In your main app.js or index.js
 * const { initializeTelemetry, createMetrics, createTracingMiddleware } = require('./monitoring/telemetry/opentelemetry-config');
 *
 * // Initialize telemetry
 * initializeTelemetry({
 *   serviceName: 'ai-orchestrator',
 *   serviceVersion: '1.0.0',
 *   environment: 'production',
 *   exporters: {
 *     traces: 'jaeger',
 *     metrics: 'prometheus'
 *   }
 * });
 *
 * // Create custom metrics
 * const metrics = createMetrics();
 *
 * // Add tracing middleware to Express
 * app.use(createTracingMiddleware());
 *
 * // Use in your code
 * const { createSpan } = require('./monitoring/telemetry/opentelemetry-config');
 *
 * async function createAgent(config) {
 *   return createSpan('createAgent', async (span) => {
 *     span.setAttribute('agent.type', config.type);
 *     span.setAttribute('agent.name', config.name);
 *
 *     // Your logic here
 *     const agent = await agentService.create(config);
 *
 *     metrics.agentCreationCounter.add(1, {
 *       type: config.type
 *     });
 *
 *     return agent;
 *   });
 * }
 */
