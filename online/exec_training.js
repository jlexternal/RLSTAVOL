function exec_training(cond_type) {

  // the argument 'cond_type' determines which training session to run

  /*
    Introduce how the experiment works and what the goal of the task is.
    i.e. Not to choose the highest number everytime, but rather to choose
    the option that on average gives the higher value.

    Run a training block where the good option starts with a lower value but is the correct shape.

    Run a training block

    Familiarise the subject with the dynamics of the VOL condition as they will not be able to
    know where the switches happen.
  */

  /* load and preload images to be used as training stimuli */
  var shapes = ['img/shape_train01.png','img/shape_train02.png','img/shape_blank.png','img/shape_spacer.png'];
  var preload = {
    type: 'preload',
    images: shapes
  };
  timeline.push(preload);
  var stimulis = shapes.slice(0,2);

  // load fullscreen plugins
  var fullscreen = {
      type: 'fullscreen',
      showtext: '<p>To take part in the experiment, your browser must be in fullscreen mode. Exiting fullscreen mode will pause the experiment. <br></br>Please click the button below to enable fullscreen mode and continue.</p>',
      buttontext: "Fullscreen",
  data: {trialType: 'instructions'}
  };
  //timeline.push(fullscreen);

  // load instructions

  // hard code reward values for the different types of training blocks
  var feedback_all = [
    /* REF */
    [[62, 59, 56, 48, 59, 73, 45, 54, 70, 67]],
    /* VOL */
    /* Note 1: The switch point is hard coded into the function debriefTableCreate.
              It will not be difficult to make this more dynamic with an argument. */
    /* Note 2: The values following the switch point are the feedback values for the WRONG choice */
    [[66, 41, 69, 50, 56, 55, 75, 78, /*switch point*/ 52, 33, 45, 50, 49, 23, 73, 46, 44, 37, 36, 26]],
    /* UNP */
     // values which fluctuate more wildly and hit closer to the extremes
    [[1,2,3]]
  ];

  /* Load feedback for the respective training session */
  var fb_session;
  switch(cond_type) {
    case 'REF':
      fb_session = feedback_all[0];
      break;
    case 'VOL':
      fb_session = feedback_all[1];
      break;
    case 'UNP':
      fb_session = feedback_all[2];
      break;
  }

  var choice_opts = ['f','j'];          // set of available keys to choices
  var n_blocks    = fb_session.length;  // number of blocks in specified training session

  // block loop
  for (iblk=0; iblk<n_blocks; iblk++) {
    let fb_vals   = fb_session[iblk]; // array of feedback for the given block
    let n_trials  = fb_vals.length;   // number of trials for given block
    let curr_iblk = iblk;

    /* Generate random placement of the correct choice
        The correct choice however, is always the shape_train01 */
    var cor_locs  = Array.from({length: n_trials}, () => Math.round(Math.random()));

    let score = 0;
    let score_arr = [];

    // trial loop
    for (itrl=0; itrl<n_trials; itrl++) {
      // localize indexed variables
      let stim_loc    = cor_locs[itrl];
      let cor_choice  = choice_opts[stim_loc];
      let stims       = [stimulis[stim_loc], stimulis[-stim_loc+1]];
      // main stimuli for each trial
      var trialstim = {
        type: "html-keyboard-response",
        stimulus: function(){
          return '<img src="' + stims[0]  + '"/><img src="img/shape_spacer.png" /><img src="' + stims[1]  + '" />';
        },
        choices: ['f','j'], // response set
        data: {
          task: 'response',
          correct_response: jsPsych.timelineVariable('correct_response'),
          condition: cond_type + '_training',
          trial_expe: itrl
        },
        on_finish: function(data){
          // correct/incorrect flag for trial
          if(jsPsych.pluginAPI.compareKeys(data.response, cor_choice)){
            data.correct = true;
            score++;
            score_arr.push(1);
          } else {
            data.correct = false;
            score_arr.push(0);
          }
        }
      };

      // update stimuli based on chosen option
      var chosen_trialstim = {
        type: "html-keyboard-response",
        stimulus: function(){
          if (jsPsych.data.get().last(1).values()[0].response == 'f') {
            return '<img src="' + stims[0]  + '"/><img src="img/shape_spacer.png" /><img src="img/shape_blank.png" />';
          }
          else {
            return '<img src="img/shape_blank.png"/><img src="img/shape_spacer.png" /><img src="' + stims[1]  + '" />';
          }
        },
        trial_duration: function() {
          if (debugFlag) {
            return 100;
          }
          else {
            return 500;
          }
        },
        choices: jsPsych.NO_KEYS
      };

      // feedback stimulus
      let val = fb_vals[itrl];
      var feedback = {
        type: 'html-keyboard-response',
        stimulus: function(){
          /* *************************************************************************
          Warning: the argument of 'last()' must be the number of trials
            'feedback' is away from 'trialstim' in the timeline push below.
            e.g. 'timeline.push(trialstim, feedback)' ->  'last(1)'                     */

          let last_trial_correct = jsPsych.data.get().last(2).values()[0].correct;
          /* *************************************************************************  */
          let fb_str;
          if (last_trial_correct) {
            fb_str = val;
          } else {
            fb_str = 100-val;
          }
          return '<div style="font-size:60px;">'+fb_str+'</div>';
        },
        choices: jsPsych.NO_KEYS,
        trial_duration: function() {
          if (debugFlag) {
            return 100;
          }
          else {
            return 1000;
          }
        },
      };

      // fixation cross stimuli
      var fixation = {
        type: 'html-keyboard-response',
        stimulus: '<div style="font-size:60px;">+</div>',
        choices: jsPsych.NO_KEYS,
        trial_duration: function(){
          if (debugFlag){
            return 100;
          }
          else {
            return 500; // remove this and uncomment line below in final
            //return jsPsych.randomization.sampleWithoutReplacement([250, 500, 750], 1)[0];
          }
        }
      };

      // initial fixation cross push
      if (itrl == 0) {
        timeline.push(fixation);
      }

      // push events to timeline
      timeline.push(trialstim,chosen_trialstim,feedback,fixation);

      // end of last trial
      if (itrl == n_trials-1){
        var trialstim_end_block = {
          type: 'html-keyboard-response',
          stimulus: function() {
            return 'end of training block: ' + score + '/' + n_trials;
          },
          choices: jsPsych.NO_KEYS,
          trial_duration: 1000
        };
        timeline.push(trialstim_end_block);

        var trialstim_end_block2 = {
          type: 'html-keyboard-response',
          stimulus: function() {
            var fb_seen = [];
            for (var i=0; i<fb_session[curr_iblk].length; i++) {
              if (score_arr[i] == 1) {
                fb_seen.push(fb_session[curr_iblk][i]);
              } else {
                fb_seen.push(100-fb_session[curr_iblk][i]);
              }
            }
            // preface to the feedback table
            let aboveTableNodeSpan = document.createElement("span");
                aboveTableNodeSpan.appendChild(document.createTextNode("Here's your performance during this training session:"));
                aboveTableNodeSpan.appendChild(document.createElement("br"));
                aboveTableNodeSpan.appendChild(document.createElement("br"));
                aboveTableNodeSpan.appendChild(document.createTextNode("The green 'O' indicates where you were correct and "));
                aboveTableNodeSpan.appendChild(document.createElement("br"));
                aboveTableNodeSpan.appendChild(document.createTextNode("The red 'X' indicates where you were incorrect."));
                aboveTableNodeSpan.appendChild(document.createElement("br"));
                aboveTableNodeSpan.appendChild(document.createElement("br"));
                if (cond_type=='REF') {
                  aboveTableNodeSpan.appendChild(document.createTextNode("As you can see, even if 'B' sometimes gave points higher than 50, "));
                  aboveTableNodeSpan.appendChild(document.createTextNode("or 'A' gave points lower than 50,"));
                  aboveTableNodeSpan.appendChild(document.createElement("br"));
                  aboveTableNodeSpan.appendChild(document.createTextNode("the only valuable cards were from deck 'A'."));
                } else if (cond_type=='VOL') {
                  aboveTableNodeSpan.appendChild(document.createTextNode("You may recall that this session was longer than the previous one. "));
                } else { // UNP

                }
                aboveTableNodeSpan.appendChild(document.createElement("br"));

            // create debriefing feedback table
            let condtype  = cond_type;
            let scorearr  = score_arr;
            let ntrials   = n_trials;
            let fbseen    = fb_seen;
            let tbl = debriefTableCreate(condtype,scorearr,ntrials,fbseen); // call the detailed feedback history function from above

            // post-feedback table commments
            let belowTableNodeSpan = document.createElement("span");
            if (cond_type=='VOL') {
                belowTableNodeSpan.appendChild(document.createTextNode("Unlike the previous game, where the good source remained constant throughout, "));
                belowTableNodeSpan.appendChild(document.createElement("br"));
                belowTableNodeSpan.appendChild(document.createTextNode("the correct source may switch over to the other option at multiple points during the game."));
                belowTableNodeSpan.appendChild(document.createElement("br"));
                belowTableNodeSpan.appendChild(document.createTextNode("Note, however, it will not flip over too fast after any given switch."));
                belowTableNodeSpan.appendChild(document.createElement("br"));
                belowTableNodeSpan.appendChild(document.createElement("br"));
            } else if (cond_type=='REF') {
              belowTableNodeSpan.appendChild(document.createTextNode("Your theoretical true/paid score is: " + score + '/' + n_trials ));
              belowTableNodeSpan.appendChild(document.createElement("br"));
              belowTableNodeSpan.appendChild(document.createElement("br"));
            }
            // continue instructions
            let continueNodeSpan = document.createElement("span");
                continueNodeSpan.style.fontWeight = 'bold';
                continueNodeSpan.appendChild(document.createTextNode('Press SPACEBAR to continue'));

            // stack the visuals to be displayed on screen
            let divDisplay = document.createElement("div"); //create new <div>
                divDisplay.appendChild(aboveTableNodeSpan);
                divDisplay.appendChild(document.createElement("br"));
                divDisplay.appendChild(tbl);
                divDisplay.appendChild(document.createElement("br"));
                divDisplay.appendChild(document.createElement("br"));
                divDisplay.appendChild(belowTableNodeSpan);
                divDisplay.appendChild(continueNodeSpan);

            return divDisplay.innerHTML;
          },
          choices: [' ']
        };
        timeline.push(trialstim_end_block2);
      }

    } // end trial loop
  } // end block loop

/*
  timeline.push({
    type: 'html-keyboard-response',
    stimulus: 'This trial will be in fullscreen mode.',
    trial_duration: 6000
  });

  // at the end of the training block, should bring the browser back out of fullscreen
  timeline.push({
    type: 'fullscreen',
    fullscreen_mode: false
  });
*/
}
