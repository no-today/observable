// ==================================================
  // Draw a Sankey diagram
  // ==================================================

function _chart(location,preprocessing,source,d3,config)
{
    /**
     * 格式化金额
     * @param {number} value - 数值
     * @param {boolean} isPositive - 是否为正数
     * @param {string} mode - 展示模式
     * @returns {string} - 格式化后的金额字符串
     */
    const formatAmount = (value, isPositive, percentage, mode) => {
        if (mode === 0 || mode === 3) {
            return "";
        }
        if (mode === 2) {
            return `${percentage}%`
        }

        // 判断符号，根据 isPositive 参数决定是正号还是负号
        let sign = isPositive ? '' : '-';

        // 判断数值是否大于等于 10000
        if (value >= 10000) {
            // 将数值除以 10000 转换为以 '万' 为单位的数值
            let formattedValue = (value / 10000).toFixed(2); // 保留两位小数
            // 使用正则表达式去掉末尾多余的 '.00' 或 '0'
            formattedValue = formattedValue.replace(/\\.00$|0$/, '');
            // 返回带符号和 '万' 单位的格式化字符串
            return `${sign}${formattedValue}万`;
        } else {
            // 数值小于 10000，直接展示
            return `${sign}${value}`;
        }
    };

    // ------------------------------------------------------------------------

    // https://github.com/observablehq/stdlib/blob/main/src/dom/uid.js
    // DOM.uid() can only be used in an observable environment
    var count = 0;
    function uid(name) {
        return new Id("O-" + (name == null ? "" : name + "-") + ++count);
    }
    function Id(id) {
        this.id = id;
        this.href = new URL(`#${id}`, location) + "";
    }
    Id.prototype.toString = function() {
        return "url(" + this.href + ")";
    };

    const data = preprocessing(source.nodes.map(d => Object.assign({}, d)), source.links.map(d => Object.assign({}, d)))

    // Create a SVG container.
    const svg = d3.create("svg")
        .attr("viewBox", [0, 0, config.width, config.height])
        .attr("style", `max-width: 100%; max-height: 100%;; height: auto; font: ${config.fontSize}px sans-serif;`);

    // Constructs and configures a Sankey generator.
    // .extent([[x0, y0], [x1, y1]])
    const sankey = d3.sankey()
        .nodeId(d => d.name)
        .nodeAlign(d3[config.nodeAlign]) // d3.sankeyLeft, etc.
        .nodeWidth(config.nodeWidth)
        .nodePadding(config.nodePadding)
        .extent([[config.extents[0], config.extents[1]], [config.width - config.extents[2], config.height - config.extents[3]]]);

    // Applies it to the data. We make a copy of the nodes and links objects
    // so as to avoid mutating the original.
    const {nodes, links} = sankey({
        nodes: data.nodes,
        links: data.links
    });

    // Defines a color scale.
    const color = d3.scaleOrdinal(d3.schemeCategory10);

    // 总资产 (目标节点
    const totalAssetsNode = nodes.filter(e => e.tag === 1)[0]
    // 净资产 (起始节点
    const netAssetsNode = nodes.filter(e => e.tag === 2)[0]

    // Creates the rects that represent the nodes.
    // Creates the rects that represent the nodes.
    const rect = svg.append("g")
        .attr("stroke", 'transparent')
      .selectAll()
      .data(nodes)
      .join("rect")
        .attr("x", d => d.tag === 1 ? d.x0 + config.dividerWidth + config.nodeWidth : d.x0)
        .attr("y", d => d.y0)
        .attr("height", d => d.y1 - d.y0)
        .attr("width", d => d.x1 - d.x0 + (d.tag === 1 ? config.boldWidth : 0))
        .attr("fill", d => d.color)
        .attr("ry", 1) // 添加垂直圆角半径

    // 负债矩形
    svg.append("rect")
      .attr("x", totalAssetsNode.x0 - config.boldWidth - config.nodeWidth) // 矩形的 x 坐标
      .attr("y", totalAssetsNode.y0) // 矩形的 y 坐标
      .attr("width", config.nodeWidth + config.boldWidth) // 矩形的宽度
      .attr("height", totalAssetsNode.y1 - totalAssetsNode.y0 - (netAssetsNode.y1 - netAssetsNode.y0)) // 减去净资产的高度
      .attr("fill", config.totalDebtNodeColor) // 矩形的填充颜色
      .attr("ry", 1) // 添加垂直圆角半径

    // Creates the paths that represent the links.
    const link = svg.append("g")
        .attr("fill", "none")
        .attr("stroke-opacity", config.linkOpacity)
        .selectAll()
        .data(links)
        .join("g")
        .style("mix-blend-mode", "multiply");

    // Creates a gradient, if necessary, for the source-target color option.
    if (config.linkColor === "source-target") {
        const gradient = link.append("linearGradient")
            .attr("id", d => (d.uid = uid("link")).id)
            .attr("gradientUnits", "userSpaceOnUse")
            .attr("x1", d => d.source.x1)
            .attr("x2", d => d.target.x0);
        gradient.append("stop")
            .attr("offset", "0%")
            .attr("stop-color", d => d.source.color);
        gradient.append("stop")
            .attr("offset", "100%")
            .attr("stop-color", d => d.target.color);
    }

    link.append("path")
        .attr("d", d => {
            // 总资产微调: 从总资产到资产，起始点后移
            if (d.source.tag === 1) {
                // 获取默认的路径字符串
                const defaultPath = d3.sankeyLinkHorizontal()(d);

                // 解析路径字符串
                const pathCommands = defaultPath.split(/(?=[A-Z])/); // 按大写字母分割路径命令
                // 对路径进行微调，例如将起始点的 x 坐标平移
                const adjustedPathCommands = pathCommands.map(command => {
                    if (command.startsWith("M")) { // 起始点命令
                        const values = command.slice(1).split(",").map(Number);
                        values[0] += config.dividerWidth; // 调整起始点的 x 坐标

                        return `M${values.join(",")}`;
                    }
                    return command;
                });

                // 生成调整后的路径字符串
                return adjustedPathCommands.join("");
            } else {
                return d3.sankeyLinkHorizontal()(d);
            }
        })
        .attr("stroke", config.linkColor === "source-target" ? (d) => d.uid
            : config.linkColor === "source" ? (d) => d.source.color
                : config.linkColor === "target" ? (d) => d.target.color
                    : config.linkColor)
        .attr("stroke-width", d => Math.max(0.5, d.width));

    // Adds labels on the nodes.
    svg.append("g")
        .selectAll()
        .data(nodes)
        .join("text")
        .attr("x", d => config.titleMode === 2 && !d.tag ? d.x1 + config.titlePadding : d.x0 - config.titlePadding)
        .attr("y", d => (d.y1 + d.y0) / 2)
        .attr("dy", "0.35em")
        .attr("text-anchor", d => config.titleMode === 2 && !d.tag ? "start" : "end")
        .text(d => d.tag === 1 ? '' : `${d.name} ${formatAmount(d.value, d.tag !== 3, d.percentage, config.displayMode)}`)

    // ------------------------------------------------------------------------

    const rectHeightCompensate = () => {
        return config.displayMode === 1 ? config.assetsRectHeight : config.assetsRectHeight * 0.5
    }

    const rectWidthCompensate = () => {
        return config.displayMode === 1 ? config.assetsRectWidth : config.assetsRectWidth * 0.7
    }

    const rectTextXCompensate = () => {
        return config.displayMode === 1 ? config.assetsRectTextX : 0
    }

    // 负债
    const totalDebtRect = svg.append("rect")
        .attr("x", totalAssetsNode.x0 - rectWidthCompensate()) // 矩形的 x 坐标
        .attr("y", totalAssetsNode.y0 - config.assetsRectPadding - rectHeightCompensate()) // 矩形的 y 坐标
        .attr("width", rectWidthCompensate()) // 矩形的宽度
        .attr("height", rectHeightCompensate()) // 矩形的高度
        .attr("fill", "rgba(128, 128, 128, 0.15)") // 矩形的填充颜色
        .attr("rx", config.assetsRectCornerRadius) // 矩形的圆角水平半径
        .attr("ry", config.assetsRectCornerRadius) // 矩形的圆角垂直半径
        .attr('opacity', config.displayMode === 1 ? 1 : 0)

    // 矩形内的标题
    svg.append("text")
        .attr("x", Number(totalDebtRect.attr("x")) + Number(totalDebtRect.attr('width')) - rectTextXCompensate())
        .attr("y", Number(totalDebtRect.attr("y")))
        .attr("dy", `${config.assetsRectTextDy}em`) // 调整垂直位置
        .attr("text-anchor", "end")
        .text(config.totalDebtText)
        .attr("fill", config.totalDebtTextColor)
        .style("font-size", config.assetsRectFontSize)
        .style("font-weight", "bold")
        .attr('opacity', 1)

    // 矩形内的数值
    svg.append("text")
        .attr("x", Number(totalDebtRect.attr("x")) + Number(totalDebtRect.attr('width')) - rectTextXCompensate()) // 控制文本位置
        .attr("y", Number(totalDebtRect.attr("y")))
        .attr("dy", `${config.assetsRectTextDy2}em`)
        .attr("text-anchor", "end")
        .text(`${formatAmount(data.totalDebt, true, null, 1)}`)
        .style("font-size", config.assetsRectFontSize2)
        //.style("font-weight", "bold")
        .attr('opacity', config.displayMode === 1 ? 1 : 0)

    // 总资产
    const totalAssetsRect = svg.append("rect")
        .attr("x", Number(totalDebtRect.attr("x")) + Number(totalDebtRect.attr('width')) + config.nodeWidth + config.dividerWidth)
        .attr("y", totalDebtRect.attr("y"))
        .attr("width", rectWidthCompensate())
        .attr("height", rectHeightCompensate())
        .attr("fill", "rgba(128, 128, 128, 0.15)")
        .attr("rx", config.assetsRectCornerRadius)
        .attr("ry", config.assetsRectCornerRadius)
        .attr('opacity', config.displayMode === 1 ? 1 : 0)

    svg.append("text")
        .attr("x", Number(totalAssetsRect.attr("x")) + rectTextXCompensate())
        .attr("y", Number(totalAssetsRect.attr("y")))
        .attr("dy", `${config.assetsRectTextDy}em`)
        .attr("text-anchor", "start")
        .text(config.totalAssetsText)
        .attr("fill", config.totalAssetsTextColor)
        .style("font-size", config.assetsRectFontSize)
        .style("font-weight", "bold")
        .attr('opacity', 1)

    svg.append("text")
        .attr("x", Number(totalAssetsRect.attr("x")) + rectTextXCompensate())
        .attr("y", Number(totalAssetsRect.attr("y")))
        .attr("dy", `${config.assetsRectTextDy2}em`)
        .attr("text-anchor", "start")
        .text(`${formatAmount(data.totalAssets, true, null, 1)}`)
        .style("font-size", config.assetsRectFontSize2)
        //.style("font-weight", "bold")
        .attr('opacity', config.displayMode === 1 ? 1 : 0)

    return svg.node();
}


function _config(linkColor,nodeAlign,displayMode,titleMode)
{
    const config = {
        linkColor: linkColor ? linkColor : 'source',
        nodeAlign: nodeAlign ? nodeAlign : 'sankeyJustify',
        displayMode: displayMode != null ? displayMode : 1, // 0: Hide, 1: Show, 2: Percentage, 3: Headline
        titleMode: titleMode ? titleMode : 1, // 1: Always Left, 2: Left and right

        totalDebtNodeColor: "#A8A7B0",
        totalAssetsText: "总资产",
        totalDebtText: "负债",
        totalAssetsTextColor: "#8F8DB5",
        totalDebtTextColor: "#990000",

        width: 700,
        height: 200,
        fontSize: 10,
        nodeWidth: 5,
        nodePadding: 13,
        titlePadding: 5,

        extents: [90, 22, 5, 0],

        linkOpacity: 0.4,
        boldWidth: 7,
        dividerWidth: 2,

        assetsRectHeight: 33,
        assetsRectWidth: 55,
        assetsRectPadding: 8,
        assetsRectCornerRadius: 5,
        assetsRectTextX: 5,
        assetsRectTextDy: 1.25,
        assetsRectTextDy2: 2.75,
        assetsRectFontSize: 11
    }

    return config
}


function _source()
{
    const nodes = [
        {name: "总资产", color: "#9191BE", tag: 1},
        {name: "信用卡", color: "#A8A7B0", tag: 3},
        {name: "房屋贷款", color: "#A8A7B0", tag: 3},
        {name: "车辆贷款", color: "#A8A7B0", tag: 3},
        {name: "个人贷款", color: "#A8A7B0", tag: 3},

        {name: "净资产", color: "#81CDB4", tag: 2},

        {name: "投资理财", color: "#908DA2"},
        {name: "后备隐藏能源", color: "#716C89"},

        {name: "固定资产", color: "#839FAD"},
        {name: "房产(自住)", color: "#5C8FA1"},
        {name: "汽车", color: "#5C8FA1"},

        {name: "应收款", color: "#908DA2"},
        {name: "借给他人的钱", color: "#716C89"}
    ];

    const links = [
        {source: "信用卡", target: "总资产", value: 3000},
        {source: "房屋贷款", target: "总资产", value: 500000},
        {source: "车辆贷款", target: "总资产", value: 40000},
        {source: "个人贷款", target: "总资产", value: 30000},

        {source: "总资产", target: "固定资产", value: 850000},
        {source: "固定资产", target: "房产(自住)", value: 800000},
        {source: "固定资产", target: "汽车", value: 50000},

        {source: "总资产", target: "投资理财", value: 50000},
        {source: "投资理财", target: "后备隐藏能源", value: 50000},

        {source: "总资产", target: "应收款", value: 20000},
        {source: "应收款", target: "借给他人的钱", value: 20000}
    ];

    return {nodes, links};
}


function _preprocessing(){return(
    function preprocessing(nodes, links) {
        const mapping = nodes.reduce((acc, item) => {
            acc.set(item.name, item)
            return acc;
        }, new Map());

        // 总资产
        const totalAssets = links.filter(e => mapping.get(e.source).tag === 1)
            .reduce((acc, cur) => acc + cur.value, 0)

        // 总负债
        const totalDebt = links.filter(e => mapping.get(e.source).tag === 3)
            .reduce((acc, cur) => acc + cur.value, 0);

        // 总资产节点名称
        const assetsNodeName = nodes.filter(e => e.tag === 1)[0].name
        // 净资产节点名称
        const netAssetsNodeName = nodes.filter(e => e.tag === 2)[0].name

        links.push({source: netAssetsNodeName, target: assetsNodeName, value: totalAssets - totalDebt})

        // 每个节点所占百分比，都是以总资产为基准
        const targetTotals = {};
        links.forEach(link => {
            if (!targetTotals[link.target]) {
                targetTotals[link.target] = 0;
            }
            targetTotals[link.target] += link.value;
        });

        links.forEach(link => {
            const key = link.target === assetsNodeName ? link.source : link.target;
            const entry = mapping.get(key);

            if (entry) {
                entry.percentage = (link.value / targetTotals[assetsNodeName] * 100).toFixed(2);
            } else {
                console.error(`No mapping found for key: ${key}`);
            }
        });

        return {nodes, links, totalAssets, totalDebt};
    }
)}
