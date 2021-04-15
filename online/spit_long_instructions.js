function spit_long_instructions (instr_type) {

var instructions_var;
let instr_gen1, instr_gen2, instr_gen3, instr_gen4, instr_gen5, instr_gen6;

switch (instr_type) {
  case 'introduction':
    instr_gen1 = '<p style = "text-align: center; font-size: 28px">' +
      "To participate in the experiment you will mainly use two keys, <br><br>" +
      "'F' and 'J'.<br><br></p>"+
      '<p style = "font-size: 24px; font-weight: bold">Press \'J\' to continue.</p>';
    instr_gen2 = '<p style = "text-align: center; font-size: 28px">' +
      "If you made it to this page, you've successfully clicked on 'J'!<br><br>" +
      '<p style = "font-size: 24px; font-weight: bold">Press \'F\' to go back.<br><br>Press \'J\' to continue.</p>';
    instr_gen3 = '<p style = "text-align: center; font-size: 28px; font-weight: bold">' +
      "Please read the following instructions very carefully.<br><br>" +
      '<p style = "font-size: 24px; font-weight: bold">Press \'F\' to go back.<br><br>Press \'J\' to continue.</p>';
    instr_gen4 = "In this experiment, you will play 3 simple games where you are drawing from 2 decks of cards. <br><br>" +
      "One of these decks gives you cards that are worth money, and the other gives you worthless cards.<br><br>" +
      "Each card that you draw is associated with in-game points ranging from 0 to 100.<br><br>"+
      '<span style = "font-weight: bold">However, this does not correspond to the money you will receive at the end.</span><br><br>'+
      '<p style = "font-size: 24px; font-weight: bold">Press \'F\' to go back.<br><br>Press \'J\' to continue.</p>';
    instr_gen5 = 'Your gain depends on the number of times you draw from the valuable deck.<br><br>' +
      'Seems simple enough, right?<br><br>' +
      'The valuable deck tends to have cards that are greater than 50 points on average, and<br>' +
      'the worthless deck tends to have cards that are lower than 50 points on average.<br><br>' +
      'Both decks provide cards that corresponds to points, but the valuable deck is only revealed at the end of a game. <br><br>' +
      'It is up to you to infer which deck has the valuable cards based on the points you receive.<br><br>'+
      '<p style = "font-size: 24px; font-weight: bold">Press \'F\' to go back.<br><br>Press \'J\' to continue.</p>';
    instructions_var = {
      type: 'instructions',
      pages: [instr_gen1, instr_gen2, instr_gen3, instr_gen4, instr_gen5],
      key_backward: 'f',
      key_forward: 'j'
    };
    break;

  case 'ref_instructions':
    instr_gen1 = 'Before we begin the first game, let\'s do some training.<br><br>' +
      'You will now play a short version of what you will play in the real game.<br><br>' +
      '<p style = "text-align: center; font-size: 28px; font-weight: bold">Press spacebar to continue.</p>';
    instructions_var = {
      type: 'html-keyboard-response',
      stimulus: instr_gen1,
      choices: [' ']
    };

    break;

}

return instructions_var;
}
