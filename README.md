# NAS-Tools 一键部署脚本

---

### 作者信息

- **作者**: Eric
- **YouTube 频道**: [https://www.youtube.com/@Eric-f2v](https://www.youtube.com/@Eric-f2v)

---

### 脚本简介

这是一个用于在 NAS（如群晖）上，一键部署以下 Docker 服务的脚本：
- **Jackett**：一个索引站点代理，用于聚合多个下载站点的搜索结果。
- **Qbittorrent**：一个功能强大的 BitTorrent 客户端。
- **NASTOOLS**：一个自动化媒体库管理工具，可以自动搜索、下载、整理和管理你的电影和电视剧。

本脚本基于纯 `docker run` 命令编写，不依赖 `docker-compose`，因此具有很高的兼容性。它会创建一个统一的目录结构，方便服务之间协同工作。

### 主要功能

- **自动化部署**：通过一个脚本，自动拉取镜像并部署所有服务。
- **统一目录映射**：将宿主机的 `/media` 目录统一映射到所有服务的 `/media` 路径，简化了后续的配置。
- **目录自动创建**：自动创建所有必要的配置和媒体目录，包括 `media/Movie`、`media/Tv` 和 `media/Link`。

### 使用方法

1.  **准备工作**
    * 确保你的 NAS 已安装 Docker。
    * 通过 SSH 登录到你的 NAS。

2.  **下载并执行脚本**
    将本脚本文件（`deploy_unified.sh`）下载到你的 NAS 任意目录，例如 `/volume1/docker/`。
    
    你也可以使用 `curl` 命令直接下载并运行：

    ```bash
    curl -fsSL https://raw.githubusercontent.com/gkyang2022/NasTool/main/NasTool.sh | bash
    ```

3.  **脚本运行过程**
    脚本会依次提示你输入 Jackett、Qbittorrent 和 NASTOOLS 的端口，以及你的用户 PUID 和 PGID。输入完成后，脚本会自动完成部署。

4.  **服务访问**
    部署成功后，你可以通过以下地址访问各个服务的 WebUI：
    - **Jackett**: `http://你的NAS_IP:你设置的Jackett端口`
    - **Qbittorrent**: `http://你的NAS_IP:你设置的Qbittorrent端口`
    - **NASTOOLS**: `http://你的NAS_IP:你设置的NASTOOLS端口`

### 后续配置

由于脚本统一了卷映射，在服务部署完成后，你需要在 WebUI 中进行如下配置：
* **Qbittorrent**：在设置中，将默认下载路径设置为 `/media`。
* **NASTOOLS**：在配置中，将电影、电视和链接的路径分别设置为 `/media/Movie`、`/media/Tv` 和 `/media/Link`。

---

### 贡献

如果你对脚本有任何建议或发现 Bug，欢迎通过 GitHub 提交 issue 或 pull request。
