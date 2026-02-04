import { authTables } from '@convex-dev/auth/server'
import { defineSchema, defineTable } from 'convex/server'
import { v } from 'convex/values'
import { EMBEDDING_DIMENSIONS } from './lib/embeddings'

const authSchema = authTables as unknown as Record<string, ReturnType<typeof defineTable>>

const users = defineTable({
  name: v.optional(v.string()),
  image: v.optional(v.string()),
  email: v.optional(v.string()),
  handle: v.optional(v.string()),
  displayName: v.optional(v.string()),
  bio: v.optional(v.string()),
  role: v.optional(v.union(v.literal('admin'), v.literal('moderator'), v.literal('user'))),
  createdAt: v.number(),
  updatedAt: v.number(),
})
  .index('email', ['email'])
  .index('handle', ['handle'])

const agents = defineTable({
  slug: v.string(),
  displayName: v.string(),
  summary: v.optional(v.string()),
  description: v.optional(v.string()),
  ownerUserId: v.id('users'),
  latestVersionId: v.optional(v.id('agentVersions')),
  tags: v.record(v.string(), v.id('agentVersions')),
  softDeletedAt: v.optional(v.number()),
  moderationStatus: v.optional(
    v.union(v.literal('active'), v.literal('hidden'), v.literal('removed')),
  ),
  stats: v.object({
    downloads: v.number(),
    installs: v.number(),
    stars: v.number(),
    versions: v.number(),
    comments: v.number(),
  }),
  createdAt: v.number(),
  updatedAt: v.number(),
})
  .index('by_slug', ['slug'])
  .index('by_owner', ['ownerUserId'])
  .index('by_updated', ['updatedAt'])
  .index('by_stats_downloads', ['statsDownloads', 'updatedAt'])
  .index('by_stats_stars', ['statsStars', 'updatedAt'])
  .index('by_active_updated', ['softDeletedAt', 'updatedAt'])

const agentVersions = defineTable({
  agentId: v.id('agents'),
  version: v.string(),
  fingerprint: v.optional(v.string()),
  changelog: v.string(),
  files: v.array(
    v.object({
      path: v.string(),
      size: v.number(),
      storageId: v.id('_storage'),
      sha256: v.string(),
      contentType: v.optional(v.string()),
    }),
  ),
  parsed: v.object({
    frontmatter: v.record(v.string(), v.any()),
    metadata: v.optional(v.any()),
    soul: v.optional(v.any()),      // SOUL.md parsed content
    user: v.optional(v.any()),       // USER.md parsed content
    skills: v.optional(v.array(v.string())),  // List of skills
  }),
  createdBy: v.id('users'),
  createdAt: v.number(),
  softDeletedAt: v.optional(v.number()),
})
  .index('by_agent', ['agentId'])
  .index('by_agent_version', ['agentId', 'version'])

const agentEmbeddings = defineTable({
  agentId: v.id('agents'),
  versionId: v.id('agentVersions'),
  ownerId: v.id('users'),
  embedding: v.array(v.number()),
  isLatest: v.boolean(),
  isApproved: v.boolean(),
  visibility: v.string(),
  updatedAt: v.number(),
})
  .index('by_agent', ['agentId'])
  .index('by_version', ['versionId'])
  .vectorIndex('by_embedding', {
    vectorField: 'embedding',
    dimensions: EMBEDDING_DIMENSIONS,
    filterFields: ['visibility'],
  })

const agentComments = defineTable({
  agentId: v.id('agents'),
  userId: v.id('users'),
  body: v.string(),
  createdAt: v.number(),
  softDeletedAt: v.optional(v.number()),
})
  .index('by_agent', ['agentId'])
  .index('by_user', ['userId'])

const agentStars = defineTable({
  agentId: v.id('agents'),
  userId: v.id('users'),
  createdAt: v.number(),
})
  .index('by_agent', ['agentId'])
  .index('by_user', ['userId'])
  .index('by_agent_user', ['agentId', 'userId'])

const agentDailyStats = defineTable({
  agentId: v.id('agents'),
  day: v.number(),
  downloads: v.number(),
  installs: v.number(),
  updatedAt: v.number(),
})
  .index('by_agent_day', ['agentId', 'day'])
  .index('by_day', ['day'])

const agentStatEvents = defineTable({
  agentId: v.id('agents'),
  kind: v.union(
    v.literal('download'),
    v.literal('star'),
    v.literal('unstar'),
    v.literal('install_new'),
    v.literal('install_reactivate'),
    v.literal('install_deactivate'),
  ),
  occurredAt: v.number(),
  processedAt: v.optional(v.number()),
})
  .index('by_unprocessed', ['processedAt'])
  .index('by_agent', ['agentId'])

const userAgentInstalls = defineTable({
  userId: v.id('users'),
  agentId: v.id('agents'),
  firstSeenAt: v.number(),
  lastSeenAt: v.number(),
  lastVersion: v.optional(v.string()),
})
  .index('by_user', ['userId'])
  .index('by_user_agent', ['userId', 'agentId'])
  .index('by_agent', ['agentId'])

const auditLogs = defineTable({
  actorUserId: v.id('users'),
  action: v.string(),
  targetType: v.string(),
  targetId: v.string(),
  metadata: v.optional(v.any()),
  createdAt: v.number(),
})
  .index('by_actor', ['actorUserId'])
  .index('by_target', ['targetType', 'targetId'])

const apiTokens = defineTable({
  userId: v.id('users'),
  label: v.string(),
  prefix: v.string(),
  tokenHash: v.string(),
  createdAt: v.number(),
  lastUsedAt: v.optional(v.number()),
  revokedAt: v.optional(v.number()),
})
  .index('by_user', ['userId'])
  .index('by_hash', ['tokenHash'])

const rateLimits = defineTable({
  key: v.string(),
  windowStart: v.number(),
  count: v.number(),
  limit: v.number(),
  updatedAt: v.number(),
})
  .index('by_key_window', ['key', 'windowStart'])
  .index('by_key', ['key'])

export default defineSchema({
  ...authSchema,
  users,
  agents,
  agentVersions,
  agentEmbeddings,
  agentComments,
  agentStars,
  agentDailyStats,
  agentStatEvents,
  userAgentInstalls,
  auditLogs,
  apiTokens,
  rateLimits,
})
