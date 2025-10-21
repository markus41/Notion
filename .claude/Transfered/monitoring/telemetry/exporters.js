/**
 * Telemetry Exporters Configuration
 *
 * Datadog, Jaeger, Prometheus exporters
 */

const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');

/**
 * Datadog Exporter Configuration
 */
class DatadogExporter {
  constructor(config = {}) {
    this.config = {
      apiKey: config.apiKey || process.env.DD_API_KEY,
      site: config.site || process.env.DD_SITE || 'datadoghq.com',
      service: config.service || 'ai-orchestrator',
      env: config.env || process.env.NODE_ENV || 'production',
      version: config.version || '1.0.0',
      ...config
    };
  }

  createTraceExporter() {
    return new OTLPTraceExporter({
      url: `https://trace-intake.${this.config.site}/v1/traces`,
      headers: {
        'DD-API-KEY': this.config.apiKey,
      },
    });
  }

  createMetricExporter() {
    return new OTLPMetricExporter({
      url: `https://api.${this.config.site}/api/v2/series`,
      headers: {
        'DD-API-KEY': this.config.apiKey,
      },
    });
  }

  getAgentConfig() {
    return {
      service: this.config.service,
      env: this.config.env,
      version: this.config.version,
      hostname: require('os').hostname(),
      tags: {
        'service.name': this.config.service,
        'env': this.config.env
      }
    };
  }
}

/**
 * Jaeger Exporter Configuration
 */
class JaegerExporter {
  constructor(config = {}) {
    this.config = {
      endpoint: config.endpoint || process.env.JAEGER_ENDPOINT || 'http://localhost:14268/api/traces',
      serviceName: config.serviceName || 'ai-orchestrator',
      ...config
    };
  }

  createTraceExporter() {
    const { JaegerExporter: OtelJaegerExporter } = require('@opentelemetry/exporter-jaeger');

    return new OtelJaegerExporter({
      endpoint: this.config.endpoint,
      tags: this.config.tags || [],
    });
  }
}

/**
 * Prometheus Exporter Configuration
 */
class PrometheusExporter {
  constructor(config = {}) {
    this.config = {
      port: config.port || parseInt(process.env.PROMETHEUS_PORT || '9464'),
      endpoint: config.endpoint || '/metrics',
      prefix: config.prefix || 'ai_orchestrator_',
      ...config
    };
  }

  createMetricReader() {
    const { PrometheusExporter: OtelPrometheusExporter } = require('@opentelemetry/exporter-prometheus');
    const { MeterProvider } = require('@opentelemetry/sdk-metrics');

    const exporter = new OtelPrometheusExporter({
      port: this.config.port,
      endpoint: this.config.endpoint,
      prefix: this.config.prefix,
    });

    console.log(`Prometheus metrics available at http://localhost:${this.config.port}${this.config.endpoint}`);

    return exporter;
  }

  // Custom Prometheus metrics
  defineCustomMetrics(meter) {
    return {
      // Agent metrics
      agentTotal: meter.createCounter('agent_total', {
        description: 'Total number of agents',
      }),
      agentActive: meter.createObservableGauge('agent_active', {
        description: 'Number of active agents',
      }),
      agentCreationDuration: meter.createHistogram('agent_creation_duration_seconds', {
        description: 'Agent creation duration in seconds',
      }),

      // Task metrics
      taskTotal: meter.createCounter('task_total', {
        description: 'Total number of tasks',
      }),
      taskDuration: meter.createHistogram('task_duration_seconds', {
        description: 'Task execution duration in seconds',
      }),
      taskQueueSize: meter.createObservableGauge('task_queue_size', {
        description: 'Number of tasks in queue',
      }),

      // HTTP metrics
      httpRequestsTotal: meter.createCounter('http_requests_total', {
        description: 'Total HTTP requests',
      }),
      httpRequestDuration: meter.createHistogram('http_request_duration_seconds', {
        description: 'HTTP request duration in seconds',
      }),

      // System metrics
      memoryUsage: meter.createObservableGauge('memory_usage_bytes', {
        description: 'Memory usage in bytes',
      }),
      cpuUsage: meter.createObservableGauge('cpu_usage_percent', {
        description: 'CPU usage percentage',
      }),
    };
  }
}

/**
 * Export factory function
 */
function createExporter(type, config) {
  switch (type) {
    case 'datadog':
      return new DatadogExporter(config);
    case 'jaeger':
      return new JaegerExporter(config);
    case 'prometheus':
      return new PrometheusExporter(config);
    default:
      throw new Error(`Unknown exporter type: ${type}`);
  }
}

module.exports = {
  DatadogExporter,
  JaegerExporter,
  PrometheusExporter,
  createExporter,
};
