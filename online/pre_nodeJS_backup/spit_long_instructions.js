function spit_long_instructions (instr_type) {

var instructions_var;
let instr_gen1, instr_gen2, instr_gen3, instr_gen4, instr_gen5, instr_gen6;

switch (instr_type) {
  case 'introduction':
    instr_gen1 = '<p style = "text-align: center; font-size: 28px">' +
      "To participate in the experiment you will mainly use two keys, <br><br>" +
      '<span style="font-weight:bold">F</span> and <span style="font-weight:bold">J</span> on your keyboard.</p><br>'+
      '<p style = "font-size: 24px; font-weight: bold">Press J to continue.</p>';
    instr_gen2 = '<p style = "text-align: center; font-size: 28px">' +
      "If you made it to this page, you've successfully clicked on "+'<span style = "font-weight: bold">J</span>!<br><br>' +
      '<p style = "font-size: 24px; font-weight: bold">Press F to go back.<br><br>Press J to continue.</p>';
    instr_gen3 = '<p style = "text-align: center; font-size: 28px; font-weight: bold">' +
      "Please read the following instructions very carefully.<br><br>" +
      '<p style = "font-size: 24px; font-weight: bold">Press F to go back.<br><br>Press J to continue.</p>';
    instructions_var = {
      type: 'instructions-faded',
      pages: [instr_gen1, instr_gen2, instr_gen3],
      key_backward: 'f',
      key_forward: 'j',
      fade_duration: duration_fn(debugFlag,500,100),
    };
    break;

  case 'keypress':
    instr_gen1 = { stimuli: [
      'In our experiment, you will play a game where you draw from one of two decks of cards represented by two symbols.<br><br>',
      "For now, we will represent the two decks with letters: <br>"+
      '<span style="font-weight:bold">A</span> and '+'<span style="font-weight:bold">B.</span><br><br>',
      'Choose either <span style="font-weight:bold">A</span> or <span style="font-weight:bold">B</span> by pressing '+'<span style="font-weight:bold">F</span> ' +
      'or '+'<span style="font-weight:bold">J</span>, respectively.<br><br>',
      '<p style = "text-align: center; font-size: 28px; font-weight: bold">Press spacebar to continue.</p>']
    };
    instructions_var = {
      type: 'html-keyboard-response-sequential-faded',
      stimulus: instr_gen1,
      choices: [' '],
      fadein_duration: duration_fn(debugFlag,1000,100),
      fadeout_duration: duration_fn(debugFlag,200,100),
      minimum_duration: duration_fn(debugFlag,1000,100),
    };
    break;

  // instructions page about the number of "games" and that certain games have multiple rounds
  case 'rounds':
    instr_gen1 = { stimuli: [
      '<p style = "font-size: 26px; font-weight: bold; text-decoration:underline">About the experiment</p><br>',
      'In this experiment, you will play 6 games.<br><br>',
      'There are 3 types of games, and you will play each type twice.<br><br>',
      'Two of these types are the same, except that one is more difficult than the other.<br>',
      'They consist of multiple rounds within the game where you will be presented with a new set of shapes at each round.<br><br>',
      'These will be labeled as <span style = "font-weight:bold">MULTIPLE ROUNDS NORMAL</span> or ' +
      '<span style = "font-weight:bold">MULTIPLE ROUNDS HARD.</span><br><br>',
      'The other type of game only has a single, but longer, round, in which the set of shapes will not change.<br>',
      'This game will be labeled as <span style = "font-weight:bold">SINGLE ROUND LONG.</span><br><br>',
      '<p style = "font-style:italic"><span style = "font-weight:bold">Note:</span> there is no carryover from one round to the next, that is,<br>'+
      'there is nothing about any game/round that will help you in understanding the symbols of any other game/round.</p><br>',
      '<p style = "text-align: center; font-size: 28px; font-weight: bold">Press spacebar to continue.</p>']
    };
    instructions_var = {
      type: 'html-keyboard-response-sequential-faded',
      stimulus: instr_gen1,
      choices: [' '],
      fadein_duration: duration_fn(debugFlag,1000,100),
      fadeout_duration: duration_fn(debugFlag,1000,100),
    };
    break;

  // instructions page about the how to use the points given by cards, and what it means to win
  case 'points1':
    instr_gen1 = { stimuli: [
      "All of the games are very simple. You simply draw from 2 decks of cards. <br><br>",
      "One of these decks gives you cards that are worth money, and the other gives you worthless cards.<br><br>",
      "Each card that you draw is associated with in-game points ranging from 0 to 100.<br><br>",
      '<span style = "font-weight: bold">However, this does not correspond to the money you will receive at the end.</span><br><br>',
      'You may be asking, <span style = "font-size:24px; font-style:italic">"What do you mean by this?"</span><br><br>',
      '<p style = "font-size: 24px; font-weight: bold">Press spacebar to continue.</p>']
    };
    instructions_var = {
      type: 'html-keyboard-response-sequential-faded',
      stimulus: instr_gen1,
      choices: [' '],
      fadein_duration: duration_fn(debugFlag,1000,100),
      fadeout_duration: duration_fn(debugFlag,1000,100),
    };
    break;

  case 'points2':
    instr_gen1 = { stimuli: [
      'Your final gain depends on the number of times you draw from the valuable deck.<br><br>',
      '<span style = "font-size:24px; font-style:italic">"How do I know which deck is the valuable deck?"</span>?<br><br>',
      '<span style = "font-weight:bold">The valuable deck tends to have cards that are greater than 50 points on average, and<br>' +
      'the worthless deck tends to have cards that are lower than 50 points on average.</span><br><br>',
      'Both decks provide cards that corresponds to points, but the valuable deck is only revealed at the end of a game. <br><br>',
      'It is up to you to infer which deck has the valuable cards based on the points you receive.<br><br>',
      'You will see how this works in the following training sessions.<br><br>',
      '<p style = "font-size: 24px; font-weight: bold">Press spacebar to continue.</p>']
    };
    instructions_var = {
      type: 'html-keyboard-response-sequential-faded',
      stimulus: instr_gen1,
      choices: [' '],
      fadein_duration: duration_fn(debugFlag,1000,100),
      fadeout_duration: duration_fn(debugFlag,1000,100),
    };
    break;

  // REF prompt needs to present the idea that one should not be overly influenced by the fluctuations once one is sure of the source
  case 'ref_instructions':
    instr_gen1 = { stimuli: [
      'Before we begin the first game, let\'s do some training.<br><br>',
      'You will now play a short version of <span style = "font-weight:bold">MULTIPLE ROUNDS NORMAL</span>.<br><br>',
      'Are you ready?<br><br>',
      '<p style = "text-align: center; font-size: 28px; font-weight: bold">Press spacebar to continue.</p>']
    };
    instructions_var = {
      type: 'html-keyboard-response-sequential-faded',
      stimulus: instr_gen1,
      choices: [' '],
      fadein_duration: duration_fn(debugFlag,1000,100),
      fadeout_duration: duration_fn(debugFlag,1000,100),
    };
    break;

  // VOL prompt needs to present the idea to keep in mind that the fluctuations are indeed informative
  // also, are participants clued in on the continuous nature of the fluctuations?
  case 'vol_instructions':
    instr_gen1 = { stimuli: [
      'This is a game with a single long round.<br><br>',
      'Here, the set of symbols will be replaced with 2 circles colored orange and blue for the entirety of the game.<br><br>'+
      'The difference in this game is that the valuable deck may switch from one to the other<br> at random points during the game.<br><br>',
      'As with the previous game, the points you receive will clue you in on whether the switch is happening<br>' +
      'or has already happened.<br><br>',
      '<span style = "text-style: italic"><span style ="font-weight: bold">Note:</span> '+
      'switches do not occur so frequently (e.g. one immediately after another)</span><br><br>',
      'As before, let\'s first train a on shorter version of <span style = "font-weight:bold">SINGLE ROUND LONG</span>.<br><br>',
      '<p style = "text-align: center; font-size: 28px; font-weight: bold">Press spacebar to continue.</p>']
    };
    instructions_var = {
      type: 'html-keyboard-response-sequential-faded',
      stimulus: instr_gen1,
      choices: [' '],
      fadein_duration: duration_fn(debugFlag,1000,100),
      fadeout_duration: duration_fn(debugFlag,1000,100),
    };
    break;

  case 'unp_instructions':
    instr_gen1 = { stimuli: ['This is a game with multiple rounds.<br><br>',
      'You will now play a short version of <span style = "font-weight:bold">MULTIPLE ROUNDS HARD</span>.<br><br>',
      'The difference between this game and the first one you played,<br>' +
      'is that the valuable deck may be less evident based on the points.<br><br>',
      '<span style = "font-style:italic"><span style = "font-weight:bold">Note:</span> '+
      'The valuable deck still gives points higher than 50 on average.</span><br><br>',
      '<p style = "text-align: center; font-size: 28px; font-weight: bold">Press spacebar to continue.</p>']
    };
    instructions_var = {
      type: 'html-keyboard-response-sequential-faded',
      stimulus: instr_gen1,
      choices: [' '],
      fadein_duration: duration_fn(debugFlag,1000,100),
      fadeout_duration: duration_fn(debugFlag,1000,100),
    };
    break;

}

return instructions_var;
}
