function exec_training(training_type) {

  // the argument 'training_type' determines which training session to run

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
  var shapes = ['img/shape_train01.png','img/shape_train02.png','img/shape_blank.png'];
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
    [[62, 59, 56, 48, 59, 73, 45, 54, 70, 67],[43, 39, 52, 58, 54]],
    [1,1,1,1,1],
    ['blah']
  ];

  /* Load feedback for the respective training session */
  var feedback_session;
  switch(training_type) {
    case 'REF':
      feedback_session = feedback_all[0];
      break;
    case 'VOL':
      feedback_session = feedback_all[1];
      break;
    case 'UNP':
      feedback_session = feedback_all[2];
      break;
  }

  var choice_opts = ['f','j'];                // set of available keys to choices
  var n_blocks    = feedback_session.length;  // number of blocks in specified training sesion

  // block loop
  for (iblk=0; iblk<n_blocks; iblk++) {
    let fb_vals   = feedback_session[iblk]; // array of feedback for the given block
    let n_trials  = fb_vals.length;        // number of trials for given block

    /* Generate random placement of the correct choice */
    var cor_locs  = Array.from({length: n_trials}, () => Math.round(Math.random()));

    // trial loop
    for (itrl=0; itrl<n_trials; itrl++) {

      /* Localize indexed variables */
      let stim_loc    = cor_locs[itrl];
      let cor_choice  = choice_opts[stim_loc];
      let stims       = [stimulis[stim_loc], stimulis[-stim_loc+1]];

      // main stimuli for each trial
      var trialstim = {
        type: "html-keyboard-response",
        stimulus: function(){
          return '<img src="' + stims[0]  + '"/><img src="' + stims[1]  + '" />';
        },
        choices: ['f','j'], // response set
        data: {
          task: 'response',
          correct_response: jsPsych.timelineVariable('correct_response'),
          condition: training_type + '_training',
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

      // update stimuli based on chosen option
      var chosen_trialstim = {
        type: "html-keyboard-response",
        stimulus: function(){
          if (jsPsych.data.get().last(1).values()[0].response == 'f') {
            return '<img src="' + stims[0]  + '"/><img src="img/shape_blank.png" />';
          }
          else {
            return '<img src="img/shape_blank.png"/><img src="' + stims[1]  + '" />';
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
            //return jsPsych.randomization.sampleWithoutReplacement([250, 500, 750, 1000, 1250], 1)[0];
          }
        }
      };

      // initial fixation stimulus push
      if (itrl == 0) {
        timeline.push(fixation);
      }

      /* push events to timeline */
      timeline.push(trialstim,chosen_trialstim,feedback,fixation);

      if (itrl == n_trials-1){
        var trialstim_end_block = {
          type: 'html-keyboard-response',
          stimulus: 'end of training block',
          choices: jsPsych.NO_KEYS,
          trial_duration: 1000
        };
        timeline.push(trialstim_end_block);
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
