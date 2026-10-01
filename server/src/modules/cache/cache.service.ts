import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis, { RedisOptions } from 'ioredis';

@Injectable()
export class CacheService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(CacheService.name);
  private redisClient: Redis | null = null;
  // Local in-memory fallback cache when Redis is unavailable
  private inMemoryCache = new Map<string, { value: string; expiry?: number }>();

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    try {
      const redisUrl = this.configService.get<string>('REDIS_URL');

      if (redisUrl && redisUrl.trim()) {
        const masked = redisUrl.replace(/:([^:@]+)@/, ':****@');
        this.logger.log(`Connecting to Redis using REDIS_URL (${masked})...`);

        const isTls = redisUrl.startsWith('rediss://');
        const redisOptions: RedisOptions = {
          maxRetriesPerRequest: 3,
          connectTimeout: 5000,
          retryStrategy: (times) => {
            if (times > 5) {
              this.logger.warn('Redis reconnection stopped after 5 attempts.');
              return null;
            }
            return Math.min(times * 300, 3000);
          },
          lazyConnect: true,
        };

        if (isTls) {
          redisOptions.tls = { rejectUnauthorized: false };
        }

        this.redisClient = new Redis(redisUrl, redisOptions);
      } else {
        const host = this.configService.get<string>('REDIS_HOST', 'localhost');
        const port = this.configService.get<number>('REDIS_PORT', 6379);
        this.logger.log(`Connecting to local Redis at ${host}:${port}...`);

        this.redisClient = new Redis({
          host,
          port,
          maxRetriesPerRequest: 1,
          connectTimeout: 2000,
          retryStrategy: () => null,
          lazyConnect: true,
        });
      }

      this.redisClient.on('connect', () => {
        this.logger.log('✅ Redis connected successfully');
      });

      this.redisClient.on('ready', () => {
        this.logger.log('🚀 Redis is ready');
      });

      this.redisClient.on('error', (err) => {
        this.logger.warn(`⚠️ Redis error: ${err.message}. Falling back to in-memory caching.`);
      });

      this.redisClient.connect().catch((err) => {
        this.logger.warn(`⚠️ Initial Redis connection failed: ${err.message}. In-memory caching active.`);
      });
    } catch (error: any) {
      this.logger.warn(`⚠️ Redis initialization failed: ${error.message}`);
    }
  }

  onModuleDestroy() {
    if (this.redisClient) {
      this.redisClient.disconnect();
      this.logger.log('🔌 Redis disconnected');
    }
  }

  async get(key: string): Promise<string | null> {
    if (this.redisClient && this.redisClient.status === 'ready') {
      try {
        return await this.redisClient.get(key);
      } catch {
        // Fall back to memory
      }
    }

    // In-memory fallback
    const item = this.inMemoryCache.get(key);
    if (item) {
      if (item.expiry && Date.now() > item.expiry) {
        this.inMemoryCache.delete(key);
        return null;
      }
      return item.value;
    }
    return null;
  }

  async set(
    key: string,
    value: any,
    ttlInSeconds?: number,
  ): Promise<void> {
    const stringValue =
      typeof value === 'string'
        ? value
        : JSON.stringify(value);

    // Save in-memory
    const expiry = ttlInSeconds ? Date.now() + ttlInSeconds * 1000 : undefined;
    this.inMemoryCache.set(key, { value: stringValue, expiry });

    // Save to Redis if ready
    if (this.redisClient && this.redisClient.status === 'ready') {
      try {
        if (ttlInSeconds) {
          await this.redisClient.set(key, stringValue, 'EX', ttlInSeconds);
        } else {
          await this.redisClient.set(key, stringValue);
        }
      } catch {
        // Ignore cache write errors
      }
    }
  }

  async delete(key: string): Promise<void> {
    this.inMemoryCache.delete(key);

    if (this.redisClient && this.redisClient.status === 'ready') {
      try {
        await this.redisClient.del(key);
      } catch {
        // Ignore cache delete errors
      }
    }
  }

  async clearPattern(pattern: string): Promise<void> {
    // Clear matching keys from memory
    const regex = new RegExp('^' + pattern.replace(/\*/g, '.*') + '$');
    for (const k of this.inMemoryCache.keys()) {
      if (regex.test(k)) {
        this.inMemoryCache.delete(k);
      }
    }

    if (this.redisClient && this.redisClient.status === 'ready') {
      try {
        const keys = await this.redisClient.keys(pattern);
        if (keys.length > 0) {
          await this.redisClient.del(...keys);
        }
      } catch {
        // Ignore cache errors
      }
    }
  }
}