---
title: 从零搭建全球资讯看板：实时新闻+股市行情一站式展示
date: 2026-03-11 19:46:00
tags:
  - Python
  - Flask
  - 开发
  - 工具
categories:
  - 效率工具
---

## 项目背景

平时经常需要刷新闻看股市行情，来回切换网站太麻烦，于是自己动手写了一个一站式的全球资讯看板，把军事/政治/财经新闻和全球主要股指行情整合到一个页面，支持一键刷新，用起来非常方便。

## 功能特性

### 📰 三类新闻分类展示
- **军事/战争新闻**：实时国际冲突、军事动态相关要闻
- **政治/政策新闻**：国内国际时政、政策发布、重要会议消息
- **财经/金融新闻**：经济数据、股市动态、行业前沿资讯

### 📈 实时股市行情
展示全球五大主要股指的实时行情：
- 上证指数
- 深证成指
- 恒生指数
- 道琼斯工业指数
- 纳斯达克综合指数

自动显示涨跌额和涨跌幅，红涨绿跌一目了然。

### 🔄 自动更新机制
- 新闻数据每5分钟自动缓存，避免频繁请求API
- 股市行情每30秒自动刷新，接近实时数据
- 点击右上角刷新按钮可以手动获取最新数据，有加载动画和成功提示

### 📱 响应式设计
采用Tailwind CSS开发，完美适配电脑、平板、手机等各种设备，随时随地都能看。

## 技术实现

### 后端架构
- **框架**：Python + Flask，轻量级Web框架，开发效率高
- **新闻数据源**：新浪新闻RSS接口，免费无需API密钥，国内访问稳定
- **股市数据源**：新浪财经API，无需认证即可获取实时行情
- **缓存机制**：内存缓存，减少重复请求，提升访问速度

### 前端技术
- **UI框架**：Tailwind CSS，现代化的原子类CSS框架，样式美观
- **图标库**：Font Awesome，提供丰富的图标支持
- **交互**：原生JavaScript实现，无需引入 heavy 的前端框架，加载速度快

## 核心代码

### 主程序入口
```python
from flask import Flask, render_template, jsonify
import requests
from bs4 import BeautifulSoup
from datetime import datetime

app = Flask(__name__)

# 新闻缓存
news_cache = {
    "war": [],
    "politics": [],
    "finance": [],
    "last_updated": 0
}

# 股市行情缓存
stock_cache = {
    "data": {},
    "last_updated": 0
}

CACHE_DURATION = 300  # 5分钟缓存
```

### 新闻获取函数
```python
def fetch_news(category):
    """获取新闻数据 - 对接新浪新闻RSS接口"""
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    # RSS接口映射
    rss_urls = {
        "war": "https://rss.sina.com.cn/news/world/focus.xml",
        "politics": "https://rss.sina.com.cn/news/china/focus.xml",
        "finance": "https://rss.sina.com.cn/finance/stock.xml"
    }
    
    response = requests.get(rss_urls.get(category, rss_urls["war"]), headers=headers, timeout=10)
    soup = BeautifulSoup(response.content, 'xml')
    items = soup.select('item')[:3]
    
    news_list = []
    for item in items:
        title = item.select_one('title').get_text(strip=True)
        pub_date = item.select_one('pubDate').get_text(strip=True)
        description = item.select_one('description').get_text(strip=True)
        
        # 计算时间差
        pub_datetime = datetime.strptime(pub_date, '%a, %d %b %Y %H:%M:%S %z')
        time_diff = datetime.now().astimezone() - pub_datetime
        hours_ago = int(time_diff.total_seconds() / 3600)
        time_str = f"{hours_ago}小时前" if hours_ago > 0 else f"{int(time_diff.total_seconds()/60)}分钟前"
        
        news_list.append({
            "title": title,
            "source": "新浪新闻" if category != "finance" else "新浪财经",
            "time": time_str,
            "summary": description[:150] + "..." if len(description) > 150 else description
        })
    
    return news_list
```

### 股市行情获取
```python
def update_stock_data():
    """获取新浪财经实时股指数据"""
    now = time.time()
    if now - stock_cache["last_updated"] < 60:  # 1分钟缓存
        return stock_cache["data"]
    
    # 股票代码映射
    stock_codes = {
        "shanghai": "sh000001",
        "shenzhen": "sz399001", 
        "hangseng": "hkHSI",
        "dow": "gb_dji",
        "nasdaq": "gb_ixic"
    }
    
    url = f"https://hq.sinajs.cn/list={','.join(stock_codes.values())}"
    response = requests.get(url, timeout=10)
    lines = response.text.split('\n')
    
    stock_data = {}
    for i, (code, sina_code) in enumerate(stock_codes.items()):
        if not lines[i]:
            continue
        data = lines[i].split('"')[1].split(',')
        if len(data) < 3:
            continue
            
        current = float(data[3])
        yesterday = float(data[2])
        change = round(current - yesterday, 2)
        change_percent = round(change / yesterday * 100, 2)
        
        stock_data[code] = {
            "name": ["上证指数", "深证成指", "恒生指数", "道琼斯工业", "纳斯达克"][i],
            "current": current,
            "change": change,
            "change_percent": change_percent,
            "is_up": change >= 0
        }
    
    stock_cache["data"] = stock_data
    stock_cache["last_updated"] = now
    return stock_data
```

## 部署方式

### 本地运行
```bash
# 安装依赖
pip install flask requests beautifulsoup4

# 运行程序
python app.py
```

访问 `http://localhost:5000` 即可使用。

### 服务器部署
推荐使用Gunicorn部署：
```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

配合Nginx反向代理可以实现HTTPS访问，适合公网部署。

## 效果展示

看板整体分为三列：
- 左侧红色卡片：军事/国际新闻
- 中间蓝色卡片：政治/政策新闻
- 右侧绿色卡片：财经/金融新闻

顶部是实时股指行情，数据每30秒自动刷新。整体界面简洁大方，信息密度适中，没有多余的广告和干扰元素。

## 后续扩展

- [ ] 添加新闻关键词搜索功能
- [ ] 支持自定义新闻来源和分类
- [ ] 添加加密货币、商品期货行情
- [ ] 配置关键词告警，出现指定关键词时发送邮件通知
- [ ] 支持新闻详情页查看和原文跳转

项目代码已经开源，需要的小伙伴可以自己部署一个，再也不用来回切换网站刷新闻看行情了！
