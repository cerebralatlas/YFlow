# 前端架构

了解 Vue 3 前端的技术实现和架构设计。

## 技术栈

- **Vue 3.4+** - UI 框架
- **TypeScript 5+** - 类型安全
- **Vite 5** - 构建工具
- **Pinia** - 状态管理
- **TanStack Vue Query** - 数据获取/缓存
- **Element Plus** - UI 组件库
- **Axios** - HTTP 客户端
- **Vue Router 4** - 路由管理

## 目录结构

```
admin-frontend/src/
├── assets/           # 静态资源
├── components/       # 公共组件
│   └── *.vue
├── layouts/          # 布局组件
│   └── MainLayout.vue
├── router/           # 路由配置
│   └── index.ts
├── services/         # API 服务
│   ├── api.ts        # Axios 实例
│   ├── auth.ts       # 认证相关
│   ├── project.ts    # 项目 API
│   └── translation.ts # 翻译 API
├── stores/           # Pinia 状态
│   ├── auth.ts       # 认证状态
│   └── project.ts    # 项目状态
├── types/            # TypeScript 类型
│   └── index.ts
├── utils/            # 工具函数
├── views/            # 页面组件
│   ├── dashboard/
│   ├── projects/
│   ├── translations/
│   ├── users/
│   └── invitations/
└── App.vue           # 根组件
```

## 状态管理

### Auth Store

管理用户认证状态：

```typescript
// stores/auth.ts
interface AuthState {
  user: User | null
  accessToken: string | null
  refreshToken: string | null
  isAuthenticated: boolean
}

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({
    user: null,
    accessToken: null,
    refreshToken: null,
    isAuthenticated: false
  }),
  actions: {
    async login(email: string, password: string) {
      const response = await api.post('/login', { email, password })
      this.setAuth(response.data)
    },
    logout() {
      this.user = null
      this.accessToken = null
      this.refreshToken = null
      this.isAuthenticated = false
    }
  }
})
```

### Project Store

管理当前项目和语言：

```typescript
// stores/project.ts
interface ProjectState {
  currentProject: Project | null
  languages: Language[]
  translations: Record<string, Record<string, string>>
}

export const useProjectStore = defineStore('project', {
  state: (): ProjectState => ({
    currentProject: null,
    languages: [],
    translations: {}
  }),
  actions: {
    async fetchTranslations(projectId: number) {
      const { data } = await translationApi.getMatrix(projectId)
      this.translations = data.translations
    }
  }
})
```

## 数据获取

使用 TanStack Vue Query 进行数据获取和缓存：

```typescript
import { useQuery } from '@tanstack/vue-query'

// 获取项目列表
const { data: projects, isLoading } = useQuery({
  queryKey: ['projects'],
  queryFn: () => projectApi.getAll()
})

// 获取翻译矩阵
const { data: translations } = useQuery({
  queryKey: ['translations', projectId],
  queryFn: () => translationApi.getMatrix(projectId),
  staleTime: 60 * 1000 // 1分钟内不重新请求
})
```

## API 服务

### Axios 配置

```typescript
// services/api.ts
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  timeout: 30000
})

// 请求拦截器 - 添加 Token
api.interceptors.request.use((config) => {
  const token = authStore.accessToken
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// 响应拦截器 - 处理错误
api.interceptors.response.use(
  (response) => response.data,
  async (error) => {
    if (error.response?.status === 401) {
      // Token 过期，尝试刷新
      await authStore.refreshToken()
    }
    return Promise.reject(error)
  }
)
```

## 路由配置

```typescript
// router/index.ts
const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/index.vue'),
    meta: { public: true }
  },
  {
    path: '/',
    component: () => import('@/layouts/MainLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/index.vue')
      },
      {
        path: 'projects',
        name: 'Projects',
        component: () => import('@/views/projects/index.vue')
      },
      {
        path: 'translations',
        name: 'Translations',
        component: () => import('@/views/translations/index.vue')
      }
    ]
  }
]
```

## 组件架构

### 翻译矩阵组件

```vue
<!-- views/translations/TranslationMatrix.vue -->
<template>
  <el-table :data="tableData" style="width: 100%">
    <el-table-column prop="key" label="Key" width="180" />
    <el-table-column
      v-for="lang in languages"
      :key="lang.code"
      :label="lang.name"
    >
      <template #default="{ row }">
        <el-input
          v-model="row.values[lang.code]"
          @blur="updateTranslation(row)"
        />
      </template>
    </el-table-column>
  </el-table>
</template>
```

## 下一步

- [后端架构 →](/architecture/backend)
- [CLI 架构 →](/architecture/cli)
