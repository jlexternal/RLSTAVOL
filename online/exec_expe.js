function exec_expe(reward_csv) {
  // 2 shapes for VOL; 10 shapes for REF; 10 shapes for UNP
  var shapes = [];
  for (var i = 1; i<13; i++) {
    let imgStr = 'img/shape' + (i.toString()).padStart(2,'0') + '.png';
    shapes.push(imgStr);
  }
  shapes.push('img/shape_blank.png'); // to replace unchosen shape

  /* Preload .PNG files to be used as stimuli */
  var preload = {
    type: 'preload',
    images: function() {
      let images = ['img/blue.png', 'img/orange.png'];
      images = images.concat(shapes);
      return images;
    }
  };
  timeline.push(preload);

  var fullscreen = {
      type: 'fullscreen',
      showtext: '<p>To take part in the experiment, your browser must be in fullscreen mode. Exiting fullscreen mode will pause the experiment. <br></br>Please click the button below to enable fullscreen mode and continue.</p>',
      buttontext: "Fullscreen",
  data: {trialType: 'instructions'}
  };
  timeline.push(fullscreen);

  var welcome_block = {
    type: 'html-keyboard-response',
    stimulus: '<p style = "text-align: center; font-size: 28px"><br>Hello and welcome to the experiment!</p>' +
      '<p style = "text-align: center; font-size: 28px">Press spacebar to continue.</p>',
    choices: [' '],
    stimulus_duration: 4000
  };
  timeline.push(welcome_block);

  // general instructions go here
  var instr_p1 = '<p style = "text-align: center; font-size: 28px">' +
    'Pretend that there are instructions here<br><br>Press \'J\' to continue.</p>';
  var instr_p2 = '<p style = "text-align: center; font-size: 28px">' +
    'Second page of the instructions...<br><br>Press \'F\' to go back. Press \'J\' to continue.</p>';
  var instructions_block = {
    type: 'instructions',
    pages: [instr_p1, instr_p2],
    key_backward: 'f',
    key_forward: 'j'
  };

  timeline.push(instructions_block);

  var n_sessions = 3;
  /* Process reward value array for correct option into JS */
  var rewards_arr = reward_csv.split(/\r\n|\n/); // takes text and splits it at carriage return points
  if (rewards_arr.length > n_sessions){
    while (rewards_arr.length != n_sessions) {
      rewards_arr.pop(); // remove empty row
    }
  }
  // convert unseparated text arrays to separated numerical arrays
  var rew_corr = [];

  for (var i=0; i<n_sessions; i++){
    let lines = rewards_arr[i].split(',').map(Number); // round the entries before bringing into js
    rew_corr.push(lines);
  }

  var choice_opts = ['f','j']; // set of available keys to choices
  var cond_types  = ['ref','vol','unp'];

  /* Session loop */
  for (var isesh=0; isesh<n_sessions; isesh++) {
    var cond_type = cond_types[isesh];
    var n_trials  = rew_corr[isesh].length; // number of trials
    var fb_vals   = rew_corr[isesh];        // feedback values for the correct option
    fb_vals       = fb_vals.map(x => Math.round(x*100));

    /* Generate random placement of the correct choice */
    var cor_locs  = Array.from({length: n_trials}, () => Math.round(Math.random()));

    /* Localize stimuli for the current session */
    var stimulis;
    if (isesh == 1) { // for VOL session
      stimulis = ['img/blue.png','img/orange.png'];
    }
    else { // for REF and UNP
      stimulis = shapes;
    }

    /* Trial loop */
    let iblk_prev;
    for (var itrl=0; itrl<n_trials; itrl++){
      /*
        Need to check to ensure that participant is in fullscreen mode
        However, this can't be enforced after every trial. Perhaps put a
        reminder after every session and after the practice.
      */
      var check_fullscreen = {
    		type: 'fullscreen',
    		showtext: '<p>You need to be in fullscreen mode to continue the experiment! <br></br>' +
                  ' Please click the button below to enter fullscreen mode.<br></br><p>',
    		buttontext: "Continue"
      };

      /* initial instructions for any condition */
      var cond_instr_array;
      if (itrl == 0) {
        switch (isesh) {
          case 0:
          // instructions for REF condition
          cond_instr_array = ['REF condition instructions'];
          break;
          case 1:
          // instructions for VOL condition
          cond_instr_array = ['VOL condition instructions'];
          break;
          case 2:
          // instructions for UNP condition
          cond_instr_array = ['UNP condition instructions'];
          break;
        }

        var cond_instruction = {
          type: 'html-keyboard-response',
          stimulus: cond_instr_array,
          choices: [' '],
          stimulus_duration: 4000
        };
        timeline.push(cond_instruction);
      }

      let iblk_curr   = idx_blocks[itrl]; // block index on current trial; starts from 1 (imported from MATLAB)

      /* Localize indexed variables */
      let stim_loc   = cor_locs[itrl];
      let cor_choice; // either 'f' or 'j'
      if (iblk_curr % 2 == 0) {
        cor_choice = choice_opts[-stim_loc+1]; // invert correct choice
      }
      else {
        cor_choice = choice_opts[stim_loc]; // location from cor_locs
      }
      /* Local declaration of the current shape set */
      let stims;
      if (isesh != 1) { // for REF and UNP, need to cycle through shapes
        stims = [stimulis[stim_loc+2*(idx_blocks[itrl]-1)], stimulis[-stim_loc+1+2*(idx_blocks[itrl]-1)]];
      }
      else { // for VOL, maintain the same shape set for entire session
        stims = [stimulis[stim_loc], stimulis[-stim_loc+1]];
      }

      // Choice options stimulus
      var trialstim = {
        type: "html-keyboard-response",
        stimulus: function(){
          return '<img src="' + stims[0]  + '"/><img src="' + stims[1]  + '" />';
        },
        choices: ['f','j'], // response set
        data: {
          task: 'response',
          correct_response: jsPsych.timelineVariable('correct_response'),
          condition: cond_type,
          trial_expe: itrl
        },
        on_finish: function(data){
          // correct/incorrect flag for trial
          if(jsPsych.pluginAPI.compareKeys(data.response, cor_choice)){
            data.correct = true;
          } else {
            data.correct = false;
          }
        }
      };

      // Stimulus that indicates a switch trial
      if (itrl > 0) {
        if (iblk_curr != iblk_prev) {
          var debug_switch_trial;
          if (debugFlag) {
            debug_switch_trial = {
              type: 'html-keyboard-response',
              stimulus: 'switch trial',
              choices: jsPsych.NO_KEYS,
              trial_duration: 1000
            };
            timeline.push(debug_switch_trial);
          }
          else {
            debug_switch_trial = {
              type: 'html-keyboard-response',
              stimulus: '<p style = "text-align: center; font-size: 28px">'+
                        'New set of shapes!<br><br>Press spacebar to continue.</p>',
              choices: [' ']
            };
            timeline.push(debug_switch_trial);
          }

        }
      }

      iblk_prev = idx_blocks[itrl]; // block index on the previous trial; there should be no calls of iblk_prev after this assignment

      var post_choice_trialstim = {
        type: "html-keyboard-response",
        stimulus: function(){
          if (jsPsych.data.get().last(1).values()[0].response == 'f') {
            return '<img src="' + stims[0]  + '"/><img src="img/shape_blank.png" />';
          }
          else {
            return '<img src="img/shape_blank.png"/><img src="' + stims[1]  + '" />';
          }
        },
        trial_duration: 500,
        choices: jsPsych.NO_KEYS
      };

      let val = fb_vals[itrl];
      // Feedback stimulus
      var feedback = {
        type: 'html-keyboard-response',
        stimulus: function(){
          /* *************************************************************************
          Warning: the argument of 'last()'' must be the number of trials
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
        trial_duration: 1000
      };

      var fixation = {
        type: 'html-keyboard-response',
        stimulus: '<div style="font-size:60px;">+</div>',
        choices: jsPsych.NO_KEYS,
        trial_duration: function(){
          if (debugFlag){
            return 250;
          }
          else {
            return 500; // remove this and uncomment line below in final
            //return jsPsych.randomization.sampleWithoutReplacement([250, 500, 750, 1000, 1250], 1)[0];
          }
        }
      };

      var debug_data = { // trial number
        type: 'html-keyboard-response',
        stimulus: itrl+1,
        choices: jsPsych.NO_KEYS,
        trial_duration: 500
      };

      var debug_data2 = { // feedback for correct/incorrect
        type: 'html-keyboard-response',
        stimulus: function(){
          let last_trial_correct = jsPsych.data.get().last(2).values()[0].correct;
          if (last_trial_correct) {
            return "correct";
          } else {
            return "wrong";
          }
        },
        choices: jsPsych.NO_KEYS,
        trial_duration: 500
      };

      // initial fixation stimulus push
      if (itrl == 0) {
        timeline.push(fixation);
      }

      // general stimulus and feedback push
      if (debugFlag) {
        timeline.push(debug_data, trialstim, feedback, debug_data2);
      }
      else {
        timeline.push(trialstim, post_choice_trialstim, feedback, fixation);
      }
    } // end trial loop
  } // end block loop



  /* Start the experiment */
  jsPsych.init({
    timeline: timeline,
    minimum_valid_rt: 100,
    on_finish: function() {
      // jsPsych.data.get().localSave('csv','mydata.csv'); // save csv file locally
      jsPsych.data.displayData();
    }
  });
} // end function exec_expe
