let fileNo = "10";

var width = 350,
    height = 350,
    centered;


// Set svg width & height
var svg = d3.select('#chart').append('svg')
    .attr('width', width)
    .attr('height', height);

var g = svg.append('g');
g.attr("transform", "translate(10, 10)");

// define scales
let scaleX = d3.scaleLinear().range([5,width-20*2]);
let scaleY = d3.scaleLinear().range([5,height-20*2]);
let scaleR = d3.scaleLinear();

/**
 * Render the problem
 */
function render(data,solData) {
    scaleX.domain(scaleX.range());
    scaleY.domain(scaleY.range());
    scaleR.domain(d3.extent(data["area"], d=>{return d.rx > d.ry ? d.rx : d.ry;}));
    scaleR.range(scaleR.domain());

    console.log("solData: ", solData);
    if (Object.keys(solData).length) {
        for (let cIdx in solData["next"]) {
            let toIdx = solData["next"][cIdx]["to"];
            console.log("toIdx: ", toIdx);
            data["area"][cIdx]["to"] = toIdx;
            data["area"][cIdx]["fromX"] = solData["p"][cIdx].x;
            data["area"][cIdx]["fromY"] = solData["p"][cIdx].y;
            data["area"][cIdx]["toX"] = solData["p"][toIdx].x;
            data["area"][cIdx]["toY"] = solData["p"][toIdx].y;
        }
    }
    console.log(data["area"]);

    let xSpan = scaleX.domain()[1]-scaleX.domain()[0];
    let ySpan = scaleY.domain()[1]-scaleY.domain()[0];

    if (xSpan > ySpan) {
        let newYMin = scaleY.domain()[0]-(xSpan - ySpan)/2;
        let newYMax = scaleY.domain()[1]+(xSpan - ySpan)/2;
        scaleY.domain([newYMin,newYMax]);
    } else {
        let newXMin = scaleX.domain()[0]-(ySpan - xSpan)/2;
        let newXMax = scaleX.domain()[1]+(ySpan - xSpan)/2;
        scaleX.domain([newXMin,newXMax]);
    }

    let N = data["area"].length;
    let areaCircles = g.selectAll(".area-ellipses").data(data["area"]).enter();
    areaCircles.append("ellipse")
        .attr("class", "area-ellipses")
        .attr("cx", d => {return scaleX(d.x);})
        .attr("cy", d => {return scaleY(d.y);})
        .attr("rx",  d => {return scaleR(d.rx);})
        .attr("ry",  d => {return scaleR(d.ry);})
        .attr("fill", "white")
        .attr("stroke", (d,i)=> {
            return "black";
            if (i == N-1) {
                return "red";
            } else { 
                return "black";
            }
        })

    if (Object.keys(solData).length) {
        let lines = g.selectAll(".from-to-line").data(data["area"]).enter();
        lines.append("line")
            .attr("class","from-to-line")
            .attr("x1", d => {return scaleX(d.fromX);})
            .attr("y1", d => {return scaleY(d.fromY);})
            .attr("x2", d => {return scaleX(d.toX);})
            .attr("y2", d => {return scaleY(d.toY);})
            .attr("stroke", "black");
    }
}

function parsePro(text) {
    let lines = text.split("\n");
    let data = {};
    data["area"] = [];
    for (let lIdx in lines) {
        lines[lIdx] = lines[lIdx].trim();
        let [x,y,rx,ry] = lines[lIdx].split(" ").map(Number);
        data["area"].push({
            x,y,rx,ry
        });
    }
    return data;
}


function parseSol(text) {
    let lines = text.split("\n");
    let data = {};
    data["next"] = [];
    data["p"] = [];
    for (let lIdx in lines) {
        lines[lIdx] = lines[lIdx].trim();
        if (lIdx == 0) {
            [data["obj"],data["opt"],data["N"]] = lines[lIdx].split(" ").map(Number); 
        } else if (lIdx <= data["N"]) {
            let pos = lines[lIdx].split(",").map(Number);
            data["p"].push({x: pos[0], y:pos[1]});
        } else if (lIdx == data["N"]+1) {
            let tos = lines[lIdx].split(" ").map(Number);
            for (let to of tos) {
                data["next"].push({to:to-1});
            }
        }
    }
    return data;
}


d3.request("./data/tspn_"+fileNo)
    .mimeType("text/plain")
    .response(d=> {return parsePro(d.responseText);})
    .get(data => {
        //  render(data, []);
         
         d3.request("./sol/tspn_"+fileNo)
            .mimeType("text/plain")
            .response(d=> {return parseSol(d.responseText);})
            .get(solData => {
                render(data, solData);
        }) 
    })