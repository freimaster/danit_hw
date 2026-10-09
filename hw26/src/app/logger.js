const winston = require('winston');
const fluentLogger = require('fluent-logger');

const sender = fluentLogger.createFluentSender('js_app', {
  host: process.env.FLUENT_HOST || 'fluentd',
  port: Number(process.env.FLUENT_PORT || 24224),
  timeout: 3.0,
  reconnectInterval: 1000
});
sender.on('error', (err) => console.error('Fluentd delivery error:', err.message));

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
  transports: [new winston.transports.Console()]
});

logger.on('data', (log) => {
  sender.emit('winston', {
    level: log.level,
    message: log.message,
    path: log.path || '',
    meta: log.meta || {},
    timestamp: log.timestamp || new Date().toISOString(),
    service: 'node-app'
  });
});

module.exports = logger;
