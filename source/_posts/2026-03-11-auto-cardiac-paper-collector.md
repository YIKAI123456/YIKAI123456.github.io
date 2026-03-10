---
title: "⚡ 摸鱼神器！我做了个全自动顶刊文献搜集机器人，每天9点准时把最新研究喂到我嘴里"
date: 2026-03-11 01:25:00 +0800
categories: [效率工具, 硬核DIY]
tags: [自动化, 谷歌全家桶, 文献检索, Python, 摸鱼]
---

> 作为一个科研狗，每天最痛苦的事是什么？是花一两个小时刷PubMed找最新文献，结果大半都是水文，纯纯浪费生命。
> 
> 于是我花了半小时搞了个全自动机器人，每天早上9点自动把顶刊最新研究整理好放进谷歌文档，我起床直接看就行，爽到飞起！

## 🤖 这个机器人能干啥？

先给你们看效果，每天早上会自动生成这样的文档：
✅ 只筛选**IF>5**的顶刊（Nature/Cell子刊+心血管顶刊，垃圾文献直接过滤）
✅ 每篇包含：标题 + 期刊 + DOI链接 + 全文摘要 + OA PDF下载链接（有开放获取的直接下）
✅ 自动按日期命名，归档到谷歌文档，永久保存
✅ 完全不用管，到点自动跑，省出来的时间多睡半小时觉它不香吗？

## 🛠️ 用到的工具
没用到啥复杂玩意儿，都是现成的工具拼起来的：
1. **[gogcli](https://github.com/steipete/gogcli)**：命令行操作谷歌全家桶的神器，不用开浏览器就能创建/写入谷歌文档
2. **PubMed API**：NCBI公开的文献检索API，免费无限制
3. **Unpaywall API**：免费查文献有没有开放获取PDF，科研党神器
4. **OpenClaw Cron**：定时调度工具，比Linux自带的crontab好用一万倍，还能看运行日志

## 👨‍💻 核心代码分享
我把核心逻辑简化了，你们拿去就能用：

### 第一步：检索文献
```python
def search_pubmed():
    base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
    date = (datetime.now() - timedelta(days=1)).strftime("%Y/%m/%d")
    query = "cardiac organoid OR heart organoid"
    
    # 搜索最新文献ID
    resp = requests.get(f"{base_url}esearch.fcgi?db=pubmed&term={query}&retmax=20&retmode=json")
    ids = resp.json()["esearchresult"]["idlist"]
    
    papers = []
    for pmid in ids:
        # 获取文献详情
        resp = requests.get(f"{base_url}efetch.fcgi?db=pubmed&id={pmid}&retmode=xml")
        soup = BeautifulSoup(resp.content, "xml")
        
        # 只保留顶刊
        journal = soup.find("Title").text
        if journal not in TOP_JOURNALS:
            continue
            
        # 找OA PDF链接
        doi = soup.find("ELocationID", {"EIdType": "doi"}).text if doi_tag else None
        pdf_url = None
        if doi:
            oa_resp = requests.get(f"https://api.unpaywall.org/v2/{doi}?email=your@email.com")
            if oa_resp.status_code == 200:
                pdf_url = oa_resp.json()["best_oa_location"]["url_for_pdf"]
        
        papers.append({
            "title": soup.find("ArticleTitle").text,
            "journal": journal,
            "doi": doi,
            "abstract": soup.find("AbstractText").text,
            "pdf_url": pdf_url
        })
    return papers
```

### 第二步：自动写入谷歌文档
```python
def create_google_doc(papers):
    # 创建空白文档
    result = subprocess.run([
        "gog", "docs", "create",
        "--title", f"心脏类器官文献汇总 - {datetime.now().strftime('%Y-%m-%d')}",
        "--json"
    ], capture_output=True, text=True)
    doc_id = json.loads(result.stdout)["id"]
    
    # 格式化内容
    content = f"# 心脏类器官最新文献汇总\n\n共检索到 {len(papers)} 篇\n\n"
    for i, paper in enumerate(papers, 1):
        content += f"## {i}. {paper['title']}\n"
        content += f"- **期刊:** {paper['journal']}\n"
        content += f"- **DOI:** [{paper['doi']}](https://doi.org/{paper['doi']})\n"
        if paper['pdf_url']:
            content += f"- **PDF:** [下载]({paper['pdf_url']})\n"
        content += f"\n### 摘要\n{paper['abstract']}\n\n---\n\n"
    
    # 写入文档
    subprocess.run([
        "gog", "docs", "write", doc_id, "--content", content
    ])
    return f"https://docs.google.com/document/d/{doc_id}/edit"
```

### 第三步：定时任务配置
用OpenClaw的cron功能，一行命令搞定每天9点自动跑：
```bash
cron add \
  --name "每日文献搜集" \
  --schedule "0 9 * * *" \
  --timezone "Asia/Shanghai" \
  --command "cd /path/to/script && python3 paper_collector.py >> /var/log/paper.log 2>&1"
```

## ✨ 可以扩展的骚操作
我目前只做了基础功能，你们还可以加这些玩法：
1. **自动推送**：跑完直接把文档链接推送到微信/企业微信/邮件，不用自己找
2. **关键词高亮**：摘要里的重要关键词（比如“分化”“纤维化”）自动标红
3. **翻译功能**：自动把摘要翻译成中文，看英文费劲的福音
4. **多源检索**：加上知网、万方、Google Scholar，中英文文献一网打尽
5. **数据统计**：每月自动生成研究趋势报告，看看哪个方向最热

## 🎉 最后说两句
现在这个机器人已经跑了快一周了，每天省我至少1小时找文献的时间，幸福感直接拉满。
其实搞科研不一定非要死磕实验，搞点这种小工具提升效率，把时间花在更重要的地方不好吗？

**完整代码我放GitHub了**：[点我拿](https://github.com/YIKAI123456/cardiac-organoid-paper-collector)
有问题评论区交流，觉得好用别忘了点个Star~😏
