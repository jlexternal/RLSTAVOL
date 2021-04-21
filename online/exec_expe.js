function exec_expe(reward_csv) {

  function chosen_trialstim_fn(stims) {
    var chosen_trialstim_var = {
      type: "html-keyboard-response",
      stimulus: function(){
        if (jsPsych.data.get().last(1).values()[0].response == 'f') {
          return '<img src="' + stims[0]  + '"/><img src="img/shape_spacer.png" /><img src="img/shape_blank.png" />';
        }
        else {
          return '<img src="img/shape_blank.png"/><img src="img/shape_spacer.png" /><img src="' + stims[1]  + '" />';
        }
      },
      trial_duration: duration_fn(debugFlag,500,100),
      choices: jsPsych.NO_KEYS
    };
    return chosen_trialstim_var;
  }

  function feedback_fn(val) {
    var feedback_var = {
      type: 'html-keyboard-response',
      stimulus: function(){
        /* *************************************************************************
        Warning: the argument of 'last()'' must be the number of trials
          'feedback' is away from 'trialstim' in the timeline push below.
          e.g. 'timeline.push(trialstim, feedback)' ->  'last(1)'                     */
        let last_trial_correct;
        if (debugFlag) {
          last_trial_correct = jsPsych.data.get().last(1).values()[0].correct;
        } else {
          last_trial_correct = jsPsych.data.get().last(2).values()[0].correct;
        }
        /* *************************************************************************  */
        let fb_str;
        if (last_trial_correct) {
          fb_str = val;
        } else {
          fb_str = 100-val;
        }
        return '<div style="font-size:60px">'+fb_str+'</div>';
      },
      choices: jsPsych.NO_KEYS,
      trial_duration: duration_fn(debugFlag,500,100),
    };
    return feedback_var;
  }

  function fixation_fn(debugFlag,longDurationFlag) {
    var fixation_var = {
      type: 'html-keyboard-response',
      stimulus: '<div style="font-size:60px;">+</div>',
      choices: jsPsych.NO_KEYS,
      trial_duration: function(){
        if (debugFlag){
          if (longDurationFlag) {
            return 1250;
          } else {
            return 200;
          }
        }
        else {
          if (longDurationFlag) {
            return 1250;
          } else {
            return jsPsych.randomization.sampleWithoutReplacement([250, 500, 750, 1000, 1250], 1)[0];
          }
        }
      }
    };
    return fixation_var;
  }

  function pre_block_label_fn(cond_num,igame,iround,nround,game_label) {
    var pre_block_label = {
      // display round number if REF or UNP
      type: 'html-keyboard-response-faded',
      stimulus: function() {
        var stim_text;
        if (cond_num != 2) { // REF and UNP
          stim_text = '<p style = "font-size: 28px; font-weight: bold">Game '+igame+'</p><br><br>' +
          game_label + '<br><br>' +
          'Round ' + iround + '/' + nround;
        } else { // VOL
          stim_text = '<p style = "font-size: 28px; font-weight: bold">Game '+igame+'</p>' + game_label;
        }
        return stim_text;
      },
      minimum_duration: duration_fn(debugFlag,1000,200),
      choices: jsPsych.NO_KEYS,
      fadein_duration: duration_fn(debugFlag,2000,100),
      fadeout_duration: duration_fn(debugFlag,2000,100),
      trial_duration: duration_fn(debugFlag,1000,100),
    };
    return pre_block_label;
  }
 function end_session_stim_fn(isesh) {
    var end_session_stim = {
      type: 'html-keyboard-response-min-duration',
      stimulus: function () {
        let igame = isesh + 1;
        return 'End of Game ' + igame +
        '<br><br><p style = "text-align: center; font-size: 28px; font-weight: bold">Press spacebar to continue.</p>';
      },
      choices: [' ']
    };
    return end_session_stim
  }

  // 2 shapes for VOL; 10 shapes for REF; 10 shapes for UNP

  // need to load new shapes for UNP
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
  //timeline.push(fullscreen); //debug

  var welcome_block = {
    type: 'html-keyboard-response-sequential-faded',
    stimulus: function () {
      var stim = {
        stimuli: ['<p style = "text-align: center; font-size: 28px"><br>Hello and welcome to the experiment!</p>',
      '<p style = "text-align: center; font-size: 28px; font-weight: bold">Press spacebar to continue.</p>']
      };
      return stim;
    },
    choices: [' '],
    fadein_duration: duration_fn(debugFlag,2000,200),
    fadeout_duration: duration_fn(debugFlag,1000,200),
    individual_durations: function () {
      var dura = {
        durations: [1000,100]
      };
      return dura;
    }
  };
  timeline.push(welcome_block);

  // test timeline pushes here: // debug


  // push introductory instructions
  timeline.push(spit_long_instructions('introduction'));

  // push simple introductory keypress training
  var instructions_keypress = {
    type: 'html-keyboard-response-sequential-faded',
    stimulus: function () {
      var stim = {
        stimuli: ['In our experiment, you will play a game where you draw from one of two decks of cards represented by two symbols.<br><br>',
          "For now, we will represent the two decks with letters: <br>"+
          '<span style="font-weight:bold">A</span> and '+'<span style="font-weight:bold">B.</span><br><br>',
          'Choose either <span style="font-weight:bold">A</span> or <span style="font-weight:bold">B</span> by pressing '+'<span style="font-weight:bold">F</span> ' + 'or '+'<span style="font-weight:bold">J</span>'+
          ", respectively.<br><br>",
          '<p style = "text-align: center; font-size: 28px; font-weight: bold">Press spacebar to continue.</p>']
        };
        return stim;
      },
    choices: [' '],
    fadein_duration: duration_fn(debugFlag,1000,200),
    fadeout_duration: duration_fn(debugFlag,1000,200),
    minimum_duration: duration_fn(debugFlag,1000,200),
  };
  timeline.push(instructions_keypress);

  var stims_ab = ['img/shape_train01.png','img/shape_train02.png'];
  var example_trial = {
    type: "html-keyboard-response",
    stimulus: function(){
      return '<img src="' + stims_ab[0]  + '"/><img src="img/shape_spacer.png" /><img src="' + stims_ab[1]  + '" />';
    },
    choices: ['f','j'], // response set
    data: {
      task: 'response'
    }
  };
  var post_example_trial = {
    type: "html-keyboard-response-sequential-faded",
    stimulus: function () {
      var stim = {
        stimuli: ['As you saw, a trial begins with the appearance of a cross in the center followed by<br>' +
        "the presentation of the two options you have.<br><br>",
        "After your choice is made, you will then see the points associated with the option.<br><br>",
        '<span style = "font-weight: bold">Be sure to pay attention to the location of your desired deck, as they may switch sides from time to time.</span><br><br>',
        '<span style = "font-style:italic; font-size:30px">'+
          '<span style="font-weight:bold">F</span> corresponds to the shape on the <span style="font-weight:bold">LEFT</span><br>'+
          'and <span style="font-weight:bold">J</span> corresponds to the shape on the <span style="font-weight:bold">RIGHT</span>'+
          '</span>',
        '<p style = "text-align: center; font-size: 28px; font-weight: bold">Press spacebar to continue.</p>']
      };
      return stim;
    },
    choices: [' '],
    fadein_duration: duration_fn(debugFlag,1000,200),
    fadeout_duration: duration_fn(debugFlag,1000,200),
    minimum_duration: duration_fn(debugFlag,2000,200),
  };
  timeline.push(fixation_fn(debugFlag),example_trial,chosen_trialstim_fn(stims_ab),feedback_fn(50),post_example_trial);

  var n_sessions = 6; //debug 6 in final
  var choice_opts = ['f','j']; // set of available keys to choices
  var cond_types  = ['REF','VOL','UNP'];

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

  /* Determine order of conditions based on participant number */
  var cond_order;
  if (subj_num % 2 == 1) {
    cond_order = [1,2,3,1,2,3]; // REF, VOL, UNP, REF, VOL, UNP
  } else {
    cond_order = [1,3,2,1,3,2]; // REF, UNP, VOL, REF, UNP, VOL
  }

  timeline.push(spit_long_instructions('rounds')); // explain the structure of the experiment
  timeline.push(spit_long_instructions('points1')); // explain how to get points
  timeline.push(spit_long_instructions('points2')); // explain how to get points

  /* Session loop */
  for (var isesh=0; isesh<n_sessions; isesh++) {

    let cond_type = cond_types[isesh];
    let game_label;
    var n_trials  = 5; //rew_corr[isesh].length; // number of trials //debug
    var fb_vals   = rew_corr[isesh];        // feedback values for the correct option
    fb_vals       = fb_vals.map(x => Math.round(x*100));

    /* initial instructions for whatever condition */
    let init_cond_instruction_str;
    switch (cond_order[isesh]) {
      case 1: // instructions for REF condition
        game_label = '<span style = "font-weight:bold">MULTIPLE ROUNDS NORMAL</span>';
        init_cond_instruction_str = 'ref_instructions';
        break;
      case 2: // instructions for VOL condition
        game_label = '<span style = "font-weight:bold">SINGLE ROUND LONG</span>';
        init_cond_instruction_str = 'vol_instructions';
        break;
      case 3: // instructions for UNP condition
        game_label = '<span style = "font-weight:bold">MULTIPLE ROUNDS HARD</span>';
        init_cond_instruction_str = 'unp_instructions';
        break;
    }

    let idx_blocks_half;
    // push specific instructions and training for the 1st instance of any condition
    if (isesh < 3) {
      timeline.push(spit_long_instructions(init_cond_instruction_str));
      exec_training(cond_type);
      idx_blocks_half = 0;
    } else {
      idx_blocks_half = 1;
    }

    var pre_block_ready = {
      type: 'html-keyboard-response-faded',
      stimulus: 'When you are ready to begin,<br><br> press <span style="font-weight:bold"> spacebar </span>',
      choices: [' '],
      minimum_duration: duration_fn(debugFlag,1000,200),
    };
    timeline.push(pre_block_ready);

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
    let score = 0;
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

      let iblk_curr   = idx_blocks[idx_blocks_half][itrl]; // block index on current trial; starts from 1 (imported from MATLAB)
      var n_blocks = 5;
      var pre_block_label;
      if (cond_order[isesh] != 2) { // REF and UNP
        if (itrl==0 | iblk_curr != iblk_prev) {
          pre_block_label = pre_block_label_fn(cond_order[isesh],isesh+1,iblk_curr,n_blocks,game_label);
          timeline.push(pre_block_label);
        }
      } else {
        if (itrl==0) { // VOL
          pre_block_label = pre_block_label_fn(cond_order[isesh],isesh+1,iblk_curr,n_blocks,game_label);
          timeline.push(pre_block_label);
        }
      }

      /* Localize indexed variables */
      let stim_loc   = cor_locs[itrl];
      let cor_choice; // either 'f' or 'j'
      cor_choice = choice_opts[stim_loc]; // location from cor_locs
      if (cond_order[isesh] == 2) {
        if (iblk_curr % 2 == 0) {
          cor_choice = choice_opts[-stim_loc+1]; // invert correct choice
        }
      }
      /* Local declaration of the current shape set */
      let stims;
      if (isesh != 1) { // for REF and UNP, need to cycle through shapes
        stims = [stimulis[stim_loc+2*(idx_blocks[idx_blocks_half][itrl]-1)], stimulis[-stim_loc+1+2*(idx_blocks[idx_blocks_half][itrl]-1)]];
      }
      else { // for VOL, maintain the same shape set for entire session
        stims = [stimulis[stim_loc], stimulis[-stim_loc+1]];
      }

      // Stimulus that indicates a switch trial
      if (itrl > 0) {
        if (iblk_curr != iblk_prev) {
          var debug_switch_trial;
          if (debugFlag) {
            debug_switch_trial = {
              type: 'html-keyboard-response',
              stimulus: 'switch trial',
              choices: jsPsych.NO_KEYS,
              trial_duration: duration_fn(debugFlag,1000,100),
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
      iblk_prev = idx_blocks[idx_blocks_half][itrl]; // block index on the previous trial; there should be no calls of iblk_prev after this assignment

      // main option stimuli
      var trialstim = {
        type: "html-keyboard-response",
        stimulus: function(){
          return '<img src="' + stims[0]  + '"/><img src="img/shape_spacer.png" /><img src="' + stims[1]  + '" />';
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
            score++
          } else {
            data.correct = false;
          }
        }
      };

      var chosen_trialstim = chosen_trialstim_fn(stims);     // choice option chosen stimulus

      let val      = fb_vals[itrl];
      var feedback = feedback_fn(val); // feedback stimulus
      var fixation = fixation_fn(debugFlag); // fixation cross stimulus

      var debug_data = {
        type: 'html-keyboard-response',
        stimulus: itrl+1,
        choices: jsPsych.NO_KEYS,
        trial_duration: 100
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
        trial_duration: 100
      };

      // initial fixation stimulus push
      if (itrl == 0) {
        timeline.push(fixation_fn(debugFlag,true));
      }
      // general stimulus and feedback push
      if (debugFlag) {
        timeline.push(debug_data, trialstim, feedback, debug_data2);
      }
      else {
        timeline.push(trialstim, chosen_trialstim, feedback, fixation);
      }

      // end of block presentation and score feedback
      if (itrl == n_trials-1) {
        // score feedback for the precedent game/session
        var trialstim_end_block_feedback = {
          type: 'html-keyboard-response-min-duration',
          stimulus: function() {
            let igame = isesh+1;
            return 'Your total score for <span style = "font-weight:bold">Game '+ igame + '</span>' +
              ' is <br><br><span style = "font-size: 32px">' + score + '/' + n_trials + '</span>' +
              '<br><br><p style = "text-align: center; font-size: 28px; font-weight: bold">Press spacebar to continue to the next game.</p>';
          },
          choices: [' '],
          minimum_duration: duration_fn(debugFlag,null,null),
        };
        timeline.push(end_session_stim_fn(isesh),trialstim_end_block_feedback);
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
