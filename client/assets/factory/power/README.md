# Factory Power Assets

D1 制作的电力设备模型，D2-A 起用于正式勘探工厂 schema 2。由仓库自有几何离线制作、导出为 GLB；运行期不通过程序几何搭建主体。

- `power-source.glb`：3×3 足印，低矮双封装模块、散热背板与正面接线柜。
- `power-junction.glb`：1×1 足印，细杆、三触点横梁与下部接线柜。
- `source-manifest.json`：源文件 / 导出文件 hash、包围盒、三角形和材质批次数。

模型中心对齐逻辑足印中心，Y=0 为地面。电源与节点的“已通电”状态不烘焙在主体中，动态连线与状态反馈由权威电力结果驱动。

制作入口与依赖见 [Factory Content Authoring](../../../../tools/factory-content/README.md)。两项已接入勘探工厂的建造、接线与回收；基础工厂 schema 1 仍保持原四类构件与预供电。D1 静态预览与 D2 正式玩法证据分开记录，不代表精细美术定稿。原 14 个工厂 GLB 和其来源清单保持不变。
