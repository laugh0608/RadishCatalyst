# Runtime Intake

本目录统一承载项目本地的自动检查、正式入口与人工复测运行数据，内容默认由 Git 忽略。

- `review-worlds/current/`：当前稳定人工复测存档；`scripts/run-slice-save-review-worlds.sh` 与 PowerShell 对应入口默认打开这里。
- `review-worlds/<topic>/`：按专题长期保留的可载入主档与备份。
- `check-runs/<topic>/`：自动检查和一次性运行目录；检查可以自行清理，但不得写到 `/tmp` 或系统临时目录。
- `YYYY-MM-DD-<topic>/`：正式入口脚本、隔离存档和专题证据，可按现有专题约定继续保留。

生产版存档仍由 `SliceSaveCatalog.DEFAULT_ROOT_DIR` 写入 `user://saves/slice/`；本目录只服务开发和复测，不改变发布存档位置。

macOS / Linux 从仓库根启动当前人工复测档：

```bash
./scripts/run-slice-save-review-worlds.sh
```

PowerShell：

```powershell
pwsh ./scripts/run-slice-save-review-worlds.ps1
```

两个入口都接受自定义复测根目录作为参数；未指定时固定使用仓库内的 `review-worlds/current/`。
