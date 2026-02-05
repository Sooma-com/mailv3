<?php header('Content-Type: image/svg+xml'); 
$radius = 9.4;
$rotation = (50.0 - (float) $_REQUEST['q']) / 50.0 * (-90);
$translate_y = $radius - $radius * cos(deg2rad($rotation));
$translate_x = $radius * sin(deg2rad($rotation));
//$translate_x = (50.0 - (float)$_REQUEST['q']) / 50.0 * (-$max_translate_x);
//$translate_y = (((float)$_REQUEST['q']) - 50.0) / 50.0 * (-$max_translate_y);


?>
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!-- Created with Inkscape (http://www.inkscape.org/) -->

<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   width="100"
   height="50"
   viewBox="0 0 26.458333 13.229167"
   version="1.1"
   id="svg8"
   sodipodi:docname="quota.svg"
   inkscape:version="0.92.1 r15371">
  <defs
     id="defs2" />
  <sodipodi:namedview
     id="base"
     pagecolor="#ffffff"
     bordercolor="#666666"
     borderopacity="1.0"
     inkscape:pageopacity="0.0"
     inkscape:pageshadow="2"
     inkscape:zoom="8"
     inkscape:cx="-69.779585"
     inkscape:cy="29.789142"
     inkscape:document-units="mm"
     inkscape:current-layer="layer1"
     showgrid="false"
     units="px"
     inkscape:window-width="3832"
     inkscape:window-height="2076"
     inkscape:window-x="2560"
     inkscape:window-y="80"
     inkscape:window-maximized="0" />
  <metadata
     id="metadata5">
    <rdf:RDF>
      <cc:Work
         rdf:about="">
        <dc:format>image/svg+xml</dc:format>
        <dc:type
           rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
        <dc:title></dc:title>
      </cc:Work>
    </rdf:RDF>
  </metadata>
  <g
     inkscape:label="Layer 1"
     inkscape:groupmode="layer"
     id="layer1"
     transform="translate(0,-283.77082)">
    <g
       id="g4509"
       transform="translate(13.229167)">
      <path
         id="rect4495"
         transform="matrix(0.26458333,0,0,0.26458333,0,270.54165)"
         d="M -0.02929688,50 A 50,50 0 0 0 -50,100 h 10 A 39.999999,39.999999 0 0 1 0,60 39.999999,39.999999 0 0 1 39.998047,99.966797 L 50,99.958984 A 50,50 0 0 0 -0.02929688,50 Z"
         style="fill:#008000;fill-opacity:1;stroke:none;stroke-width:6.50791311;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"
         inkscape:connector-curvature="0" />
      <path
         id="rect4487"
         transform="matrix(0.26458333,0,0,0.26458333,0,270.54165)"
         d="m 40.392578,70.634766 -8.078125,5.873046 a 39.999999,39.999999 0 0 1 7.683594,23.458985 L 50,99.958984 A 50,50 0 0 0 40.392578,70.634766 Z"
         style="fill:#ff0000;fill-opacity:1;stroke:none;stroke-width:12.3674345;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"
         inkscape:connector-curvature="0" />
    </g>
    <path
       sodipodi:type="star"
       style="fill:#000000;fill-opacity:1;stroke:none;stroke-width:0.95865387;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"
       id="path4511"
       sodipodi:sides="3"
       sodipodi:cx="13.229167"
       sodipodi:cy="287.48602"
       sodipodi:r1="2.5545373"
       sodipodi:r2="1.2772686"
       sodipodi:arg1="2.6179939"
       sodipodi:arg2="3.6651914"
       d="m 11.016873,288.76329 1.106147,-1.9159 1.106147,-1.9159 1.106147,1.9159 1.106147,1.9159 -2.212294,0 z"
       transform="translate(<?= $translate_x ?>, <?= $translate_y ?>) rotate(<?= $rotation ?>,13.229167,287.48602)" />
    <text
       xml:space="preserve"
       style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:4.11171722px;line-height:125%;font-family:sans-serif;-inkscape-font-specification:sans-serif;text-align:center;letter-spacing:0px;word-spacing:0px;text-anchor:middle;fill:#000000;fill-opacity:1;stroke:none;stroke-width:0.10279292px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
       x="13.685659"
       y="296.3309"
       id="text4515"><tspan
         sodipodi:role="line"
         id="tspan4513"
         x="13.685659"
         y="296.3309"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-family:sans-serif;-inkscape-font-specification:sans-serif;text-align:center;text-anchor:middle;stroke-width:0.10279292px"><?= $_REQUEST['q'] ?>%</tspan></text>
<?php if ( ((int) $_REQUEST['q']) >= 80 ) { ?>
    <g
       id="warning"
       transform="matrix(0.51344422,0,0,0.51344422,22.503743,143.8061)">
      <path
         inkscape:transform-center-y="-1.2498434"
         d="m -18.355469,280.45818 2.164793,3.74953 2.164792,3.74953 -4.329585,0 -4.329585,0 2.164793,-3.74953 z"
         inkscape:randomized="0"
         inkscape:rounded="0"
         inkscape:flatsided="false"
         sodipodi:arg2="-0.52359878"
         sodipodi:arg1="-1.5707963"
         sodipodi:r2="2.499687"
         sodipodi:r1="4.9993739"
         sodipodi:cy="285.45755"
         sodipodi:cx="-18.355469"
         sodipodi:sides="3"
         id="path4521"
         style="fill:none;fill-opacity:1;stroke:#ff0000;stroke-width:0.79374999;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"
         sodipodi:type="star" />
      <g
         id="text4525"
         style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:5.75538063px;line-height:125%;font-family:'Bitstream Vera Sans';-inkscape-font-specification:'Bitstream Vera Sans';letter-spacing:0px;word-spacing:0px;fill:#000000;fill-opacity:1;stroke:none;stroke-width:0.14388451px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
         aria-label="!">
        <path
           id="path4527"
           style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-family:Consolas;-inkscape-font-specification:Consolas;stroke-width:0.14388451px"
           d="m -18.057582,282.89158 -0.07588,2.89455 h -0.432777 l -0.08431,-2.89455 z m -0.295076,3.27956 q 0.07588,0 0.143323,0.0309 0.06745,0.0281 0.11522,0.0787 0.05058,0.0506 0.07869,0.12084 0.03091,0.0674 0.03091,0.14332 0,0.0759 -0.03091,0.14332 -0.0281,0.0675 -0.07869,0.11803 -0.04777,0.0478 -0.11522,0.0759 -0.06745,0.0309 -0.143323,0.0309 -0.07869,0 -0.146133,-0.0309 -0.06744,-0.0281 -0.11803,-0.0759 -0.05058,-0.0506 -0.0815,-0.11803 -0.0281,-0.0674 -0.0281,-0.14332 0,-0.0759 0.0281,-0.14332 0.03091,-0.0703 0.0815,-0.12084 0.05059,-0.0506 0.11803,-0.0787 0.06745,-0.0309 0.146133,-0.0309 z"
           inkscape:connector-curvature="0" />
      </g>
    </g>
<?php } ?>
  </g>
</svg>
