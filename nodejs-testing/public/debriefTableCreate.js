function debriefTableCreate(cond_type,score_arr,n_trials,fb_seen) {
  // from https://stackoverflow.com/questions/14643617/create-table-using-javascript

  vol_switch_index = 8; // index in feedback array where the switch occurs

  /* Should also try color coding the feedback to be more clear and distinctiv */

  var score_arr_modified = score_arr;
      score_arr_modified.unshift(0);
  var tbl  = document.createElement('table');
      tbl.style.margin = "auto";
  // fill table with values
  for (var i=0; i<5; i++) { // go through rows
    var tr = tbl.insertRow();
    for (var j=0; j<n_trials+1; j++) { // go through each cell in row
      var tc = tr.insertCell();
      if (i % 2 == 0) {
        let cellContent;
        let span = document.createElement('span');
        // j==0 is the column reserved for all the labels
        if (i==0 & j==0) {        // label 'A'
          span.style.fontSize = "40px";
          span.style.float = "center";
          cellContent = 'A';
        } else if (i==2 & j==0) { // label 'Score:'
          span.style.float = "right";
          cellContent = 'Score:';
        } else if (i==4 & j==0) { // label 'B'
          span.style.fontSize = "40px";
          span.style.float = "center";
          cellContent = 'B';
        } else if (i==2) {        // feedback seen
          if (j==vol_switch_index+1 & cond_type=='VOL') { // highlight switch point
            span.style.textDecoration = "underline";
            span.style.fontWeight     = "bold";
          }
          cellContent = '     '+fb_seen[j-1]+'     ';
        } else if (i==0) {        // when A was chosen
            if (score_arr_modified[j] == 1) {
              if (cond_type == 'VOL') { // VOL condition post-switch point handling
                if (j<vol_switch_index+1){
                  span.style.color       = "green";
                  span.style.fontWeight  = "bold";
                  span.style.marginLeft  = "10px";
                  span.style.marginRight = "10px";
                  cellContent = 'O';
                } else {
                  span.style.color       = "red";
                  span.style.fontWeight  = "bold";
                  span.style.marginLeft  = "10px";
                  span.style.marginRight = "10px";
                  cellContent = 'X';
                }
              } else {
                span.style.color       = "green";
                span.style.fontWeight  = "bold";
                span.style.marginLeft  = "10px";
                span.style.marginRight = "10px";
                cellContent = 'O';
              }
            } else {
              cellContent = ' ';
            }
        } else if (i==4) {        // when B was chosen
            if (score_arr_modified[j] == 0) {
              if (cond_type == 'VOL') { // VOL condition post-switch point handling
                if (j<vol_switch_index+1){
                  span.style.color       = "red";
                  span.style.fontWeight  = "bold";
                  span.style.marginLeft  = "10px";
                  span.style.marginRight = "10px";
                  cellContent = 'X';
                } else {
                  span.style.color       = "green";
                  span.style.fontWeight  = "bold";
                  span.style.marginLeft  = "10px";
                  span.style.marginRight = "10px";
                  cellContent = 'O';
                }
              } else {
                span.style.color       = "red";
                span.style.fontWeight  = "bold";
                span.style.marginLeft  = "10px";
                span.style.marginRight = "10px";
                cellContent = 'X';
              }

            } else {
              cellContent = ' ';
            }
        } else { // blank cells
          cellContent = ' ';
        }
        cellNode = document.createTextNode(cellContent);
        span.appendChild(cellNode);
        tc.appendChild(span);
      }
      else {
        tc.appendChild(document.createTextNode(' '));
      }
    }
  }
  return tbl;
}
