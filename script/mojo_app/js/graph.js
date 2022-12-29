
let radius = 16;
let vertex_radius = 16;
let image_size = 500;

let recolor_percentage = 5;

let edge_color = [];

// -----------------------------------------------------------------------

function setup() {
  let myCanvas = createCanvas(image_size, image_size);
  myCanvas.parent('graph_div');
}

// -----------------------------------------------------------------------

function draw() {
      main();
}

// -----------------------------------------------------------------------

function main() {
  // background(255,0,255);
  // background(random_color());
  background(255);

  // g = getGraph();
  g = window.g;
  if ( g != null ) {
     output_graph(g);
  }
}
// -----------------------------------------------------------------------

function random_color() {
  return [ random(255), random(255), random(255) ];
}
// -----------------------------------------------------------------------

function onlyUnique(value, index, self) {
    return self.indexOf(value) === index;
}

// -----------------------------------------------------------------------

function output_graph(g) {
    let edge_refs = g.split(',');
    let vertex_refs = g.split(/\D+/);
    let uniq_vertices = vertex_refs.filter(onlyUnique);
    let v = uniq_vertices.length;

    // Compute angle between vertices
    let angle_between_vertices = PI * 2 / v;

    // Compute Center of image
    let x_center = image_size / 2;
    let y_center = x_center;
    let border   = 0; //parseInt( image_size / 25 );  // cellpadding in the image

    // Compute vertex coordinates
    let radius   = ( image_size / 2 ) - border;
    let angle    = Math.PI * ( 0.5 - ( 1 / v ) );
    let vertices = uniq_vertices.sort();

    let vertex_coordinates = [];
    for ( let i = 0; i < v; i++ ) {
      let vertex = vertices[i];
      let x = ( radius * cos(angle) ) + x_center;
      let y = ( radius * sin(angle) ) + y_center;
      vertex_coordinates[vertex] = { "x": x, "y": y };
      angle += angle_between_vertices;

      draw_vertex(x,y);
    }

    draw_edges(vertex_coordinates,edge_refs);

}

// -----------------------------------------------------------------------

function draw_edges(vertex_coordinates,edge_refs) {

  for( let j = 0; j < edge_refs.length; j++ ) {

    let edge_ref = edge_refs[j].split('=');

    let v1 = edge_ref[0];
    let v2 = edge_ref[1];

    let x1 = vertex_coordinates[ v1 ].x;
    let y1 = vertex_coordinates[ v1 ].y;
    let x2 = vertex_coordinates[ v2 ].x;
    let y2 = vertex_coordinates[ v2 ].y;

    let e_color = [0, 0, 0];
    stroke( e_color );
    line( x1, y1, x2, y2 );
  }

}

// -----------------------------------------------------------------------

function get_edge_color(v1,v2) {
  let e_color = random_color();
  if ( (edge_color === undefined) || (edge_color[ v1 ] === undefined )) {
    edge_color[ v1 ] = [];
  }
  edge_color[ v1 ][ v2 ] = e_color;
  return e_color;
}


// -----------------------------------------------------------------------

function draw_vertex(x,y) {
  // TODO: Add vertex labels
  // Draw vertex
  stroke(0);
  fill(255);
  ellipse(x,y,vertex_radius,vertex_radius);
}

// -----------------------------------------------------------------------
