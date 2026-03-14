/*
 * DICE POKER (Simplified)
 * A 2-player, best-of-three d6 game.
 *
 * Round flow:
 * 1) Initial Bet
 * 2) First Roll
 * 3) Raise / Accept / Re-raise / Surrender
 * 4) Re-roll Selection
 * 5) Second Roll and Final Comparison
 *
 * If both final hands compare perfectly equal, Sudden Death repeats:
 * - extra raise phase
 * - extra re-roll phase
 * until one hand exceeds the other.
 */

#define DICE_POKER_RANK_NOTHING 0
#define DICE_POKER_RANK_PAIR 1
#define DICE_POKER_RANK_TWO_PAIR 2
#define DICE_POKER_RANK_TRIPS 3
#define DICE_POKER_RANK_STRAIGHT_5 4
#define DICE_POKER_RANK_STRAIGHT_6 5
#define DICE_POKER_RANK_FULL_HOUSE 6
#define DICE_POKER_RANK_FOUR_KIND 7
#define DICE_POKER_RANK_FIVE_KIND 8

/proc/dice_poker_rank_name(rank)
	switch(rank)
		if(DICE_POKER_RANK_FIVE_KIND)
			return "Five-of-a-Kind"
		if(DICE_POKER_RANK_FOUR_KIND)
			return "Four-of-a-Kind"
		if(DICE_POKER_RANK_FULL_HOUSE)
			return "Full House"
		if(DICE_POKER_RANK_STRAIGHT_6)
			return "Six High Straight"
		if(DICE_POKER_RANK_STRAIGHT_5)
			return "Five High Straight"
		if(DICE_POKER_RANK_TRIPS)
			return "Three-of-a-Kind"
		if(DICE_POKER_RANK_TWO_PAIR)
			return "Two Pairs"
		if(DICE_POKER_RANK_PAIR)
			return "Pair"
		else
			return "Nothing"

/proc/dice_poker_sorted_desc(list/L)
	var/list/out = L.Copy()
	for(var/i in 1 to out.len)
		for(var/j in i + 1 to out.len)
			if(out[j] > out[i])
				var/t = out[i]
				out[i] = out[j]
				out[j] = t
	return out

/proc/dice_poker_eval(list/hand) as list
	var/list/result = list(
		"rank" = DICE_POKER_RANK_NOTHING,
		"name" = "Nothing",
		"vector" = list()
	)

	if(!hand || hand.len != 5)
		result["name"] = "Invalid"
		return result

	var/list/counts = list(0, 0, 0, 0, 0, 0)
	for(var/v in hand)
		if(v < 1 || v > 6)
			continue
		counts[v]++

	var/is_12345 = (counts[1] == 1 && counts[2] == 1 && counts[3] == 1 && counts[4] == 1 && counts[5] == 1)
	var/is_23456 = (counts[2] == 1 && counts[3] == 1 && counts[4] == 1 && counts[5] == 1 && counts[6] == 1)

	var/five_kind_face = 0
	var/four_kind_face = 0
	var/trips_face = 0
	var/list/pairs = list()
	var/list/singles = list()

	for(var/f in 1 to 6)
		if(counts[f] == 5)
			five_kind_face = f
		if(counts[f] == 4)
			four_kind_face = f
		if(counts[f] == 3)
			trips_face = f
		if(counts[f] == 2)
			pairs += f
		if(counts[f] == 1)
			singles += f

	if(five_kind_face)
		result["rank"] = DICE_POKER_RANK_FIVE_KIND
		result["name"] = dice_poker_rank_name(DICE_POKER_RANK_FIVE_KIND)
		result["vector"] = list(five_kind_face)
		return result

	if(four_kind_face)
		result["rank"] = DICE_POKER_RANK_FOUR_KIND
		result["name"] = dice_poker_rank_name(DICE_POKER_RANK_FOUR_KIND)
		var/list/ordered_single = dice_poker_sorted_desc(singles)
		result["vector"] = list(four_kind_face, ordered_single.len ? ordered_single[1] : 0)
		return result

	if(trips_face && pairs.len == 1)
		result["rank"] = DICE_POKER_RANK_FULL_HOUSE
		result["name"] = dice_poker_rank_name(DICE_POKER_RANK_FULL_HOUSE)
		result["vector"] = list(trips_face, pairs[1])
		return result

	if(is_23456)
		result["rank"] = DICE_POKER_RANK_STRAIGHT_6
		result["name"] = dice_poker_rank_name(DICE_POKER_RANK_STRAIGHT_6)
		result["vector"] = list(6)
		return result

	if(is_12345)
		result["rank"] = DICE_POKER_RANK_STRAIGHT_5
		result["name"] = dice_poker_rank_name(DICE_POKER_RANK_STRAIGHT_5)
		result["vector"] = list(5)
		return result

	if(trips_face)
		result["rank"] = DICE_POKER_RANK_TRIPS
		result["name"] = dice_poker_rank_name(DICE_POKER_RANK_TRIPS)
		var/list/kickers = dice_poker_sorted_desc(singles)
		var/list/vector = list(trips_face)
		for(var/k in kickers)
			vector += k
		result["vector"] = vector
		return result

	if(pairs.len == 2)
		var/list/ordered_pairs = dice_poker_sorted_desc(pairs)
		var/list/ordered_single2 = dice_poker_sorted_desc(singles)
		result["rank"] = DICE_POKER_RANK_TWO_PAIR
		result["name"] = dice_poker_rank_name(DICE_POKER_RANK_TWO_PAIR)
		result["vector"] = list(ordered_pairs[1], ordered_pairs[2], ordered_single2.len ? ordered_single2[1] : 0)
		return result

	if(pairs.len == 1)
		result["rank"] = DICE_POKER_RANK_PAIR
		result["name"] = dice_poker_rank_name(DICE_POKER_RANK_PAIR)
		var/list/kickers2 = dice_poker_sorted_desc(singles)
		var/list/vector2 = list(pairs[1])
		for(var/k2 in kickers2)
			vector2 += k2
		result["vector"] = vector2
		return result

	result["rank"] = DICE_POKER_RANK_NOTHING
	result["name"] = dice_poker_rank_name(DICE_POKER_RANK_NOTHING)
	result["vector"] = dice_poker_sorted_desc(hand)
	return result

/proc/dice_poker_compare(list/eval_a, list/eval_b)
	if(!eval_a || !eval_b)
		return 0
	var/rank_a = eval_a["rank"]
	var/rank_b = eval_b["rank"]
	if(rank_a > rank_b)
		return 1
	if(rank_b > rank_a)
		return -1

	var/list/vec_a = eval_a["vector"]
	var/list/vec_b = eval_b["vector"]
	var/max_len = max(vec_a ? vec_a.len : 0, vec_b ? vec_b.len : 0)
	for(var/i in 1 to max_len)
		var/av = (vec_a && i <= vec_a.len) ? vec_a[i] : 0
		var/bv = (vec_b && i <= vec_b.len) ? vec_b[i] : 0
		if(av > bv)
			return 1
		if(bv > av)
			return -1

	return 0

/proc/dice_poker_hand_to_text(list/hand)
	var/list/parts = list()
	for(var/v in hand)
		parts += "[v]"
	return jointext(parts, " - ")


/datum/dice_poker_game
	var/list/mob/living/players = list()
	var/list/round_wins = list()       // assoc: mob -> int
	var/list/hands = list()            // assoc: mob -> list of five ints
	var/list/rolls_used = list()       // assoc: mob -> int (base round rolls, max 2)
	var/list/selected_reroll = list()  // assoc: mob -> list of indexes (1..5)
	var/list/reroll_mask = list()      // assoc: mob -> bitmask of selected indexes (bit 1 = die 1)
	var/list/bet_caps = list()         // assoc: mob -> int (experience-scaled cap)

	var/current_player_index = 0
	var/mob/living/current_player = null
	var/mob/living/last_round_loser = null
	var/mob/living/round_starter = null

	var/current_bet = 10
	var/min_bet = 10
	var/round_number = 0

	var/phase = "joining" // joining, initial_bet, initial_roll, betting, reroll_select, showdown, game_over
	var/busy = FALSE
	var/joining = TRUE
	var/max_players = 2
	var/can_take_action = FALSE

	var/obj/item/storage/pill_bottle/dice/dice_poker/game_bag

/datum/dice_poker_game/proc/get_exp_cap(mob/living/M)
	if(!M)
		return 20
	var/luck_val = 0
	if("STALUC" in M.vars)
		luck_val = text2num("[M.vars["STALUC"]]")
	luck_val = clamp(luck_val, 0, 20)
	return 20 + (luck_val * 2)

/datum/dice_poker_game/proc/get_opponent(mob/living/M)
	for(var/mob/living/P in players)
		if(P != M)
			return P
	return null

/datum/dice_poker_game/proc/try_join(mob/living/joiner)
	if(!joiner || !joiner.client)
		return
	if(!joining)
		to_chat(joiner, span_warning("The Dice Poker game has already started."))
		return

	if(joiner in players)
		var/list/opts = list("Leave game")
		if(players.len >= 2)
			opts += "Start game now"
		var/choice = input(joiner, "You are already in the lobby. ([players.len]/[max_players] players)", "Dice Poker") as null|anything in opts
		if(choice == "Start game now")
			start_game()
		else if(choice == "Leave game")
			players -= joiner
			round_wins -= joiner
			hands -= joiner
			rolls_used -= joiner
			selected_reroll -= joiner
			bet_caps -= joiner
			game_bag.visible_message(span_notice("[joiner] left the pre-game lobby. ([players.len]/[max_players])"))
			if(!players.len)
				cancel_game(joiner)
		return

	if(players.len >= max_players)
		to_chat(joiner, span_warning("Dice Poker is full ([max_players]/[max_players])."))
		return

	players += joiner
	round_wins[joiner] = 0
	hands[joiner] = list()
	rolls_used[joiner] = 0
	selected_reroll[joiner] = list()
	reroll_mask[joiner] = 0
	bet_caps[joiner] = get_exp_cap(joiner)

	game_bag.visible_message(span_notice("[joiner] joined Dice Poker! ([players.len]/[max_players] players)"))
	if(players.len >= max_players)
		start_game()

/datum/dice_poker_game/proc/leave_game(mob/living/leaver)
	if(!(leaver in players))
		to_chat(leaver, span_warning("You are not in this Dice Poker game."))
		return

	players -= leaver
	round_wins -= leaver
	hands -= leaver
	rolls_used -= leaver
	selected_reroll -= leaver
	reroll_mask -= leaver
	bet_caps -= leaver

	game_bag.visible_message(span_notice("[leaver] leaves Dice Poker."))

	if(!players.len)
		cancel_game(leaver)
		return

	if(joining)
		if(players.len < 2)
			cancel_game(leaver)
		return

	var/mob/living/winner = players[1]
	end_game_with_winner(winner, "forfeit")

/datum/dice_poker_game/proc/cancel_game(mob/living/canceller)
	game_bag.visible_message(span_warning("[canceller] has cancelled Dice Poker!"))
	game_bag.active_game = null
	qdel(src)

/datum/dice_poker_game/proc/start_game()
	if(!joining)
		return
	if(players.len < 2)
		return

	joining = FALSE
	phase = "initial_roll"
	current_player = null
	current_player_index = 0
	last_round_loser = null
	current_bet = min_bet
	round_number = 0

	for(var/mob/living/P in players)
		round_wins[P] = 0
		rolls_used[P] = 0
		selected_reroll[P] = list()
		reroll_mask[P] = 0
		bet_caps[P] = get_exp_cap(P)
		hands[P] = list()

	game_bag.visible_message(span_notice("Dice Poker begins! Best of three rounds. Starting bet: [current_bet]."))
	start_round()

/datum/dice_poker_game/proc/start_round()
	if(phase == "game_over")
		return

	round_number++
	phase = "initial_bet"
	for(var/mob/living/P in players)
		rolls_used[P] = 0
		selected_reroll[P] = list()
		reroll_mask[P] = 0
		hands[P] = list()
		bet_caps[P] = get_exp_cap(P)

	if(last_round_loser && (last_round_loser in players))
		current_player_index = players.Find(last_round_loser)
	else
		current_player_index = 1

	if(current_player_index < 1 || current_player_index > players.len)
		current_player_index = 1

	current_player = players[current_player_index]
	round_starter = current_player
	can_take_action = TRUE

	game_bag.visible_message(span_notice("--- DICE POKER ROUND [round_number] --- Bet: [current_bet] | Score: [get_round_score_display()]"))
	game_bag.visible_message(span_notice("[current_player] starts this round and opens the initial bet."))
	to_chat(current_player, span_notice("Use the dice bag and choose Bet / Respond to open betting."))

/datum/dice_poker_game/proc/player_action(mob/living/user, action)
	if(!(user in players))
		to_chat(user, span_notice("Current score: [get_round_score_display()]"))
		return
	if(busy)
		to_chat(user, span_notice("Please wait a moment..."))
		return
	if(!can_take_action)
		to_chat(user, span_notice("Please wait for the current action to resolve."))
		return
	if(user != current_player)
		to_chat(user, span_notice("It's not your turn. Current phase: [phase]."))
		return

	if(action == "Roll Dice")
		if(phase != "initial_roll")
			to_chat(user, span_notice("Roll Dice is only available in the first-roll phase."))
			return
		do_initial_roll(user)
		return

	if(action == "Bet / Respond")
		if(phase != "initial_bet" && phase != "betting")
			to_chat(user, span_notice("Betting actions are not active right now."))
			return
		do_betting_phase(user)
		return

	if(action == "Select Re-roll")
		if(phase != "reroll_select")
			to_chat(user, span_notice("Re-roll selection is not active right now."))
			return
		do_select_and_reroll(user)
		return

	to_chat(user, span_notice("That option is not available right now."))

/datum/dice_poker_game/proc/do_initial_roll(mob/living/roller)
	if(roller != current_player)
		return
	if(rolls_used[roller] >= 1)
		to_chat(roller, span_notice("You already made your first roll this round."))
		return

	busy = TRUE
	can_take_action = FALSE
	playsound(game_bag, 'sound/items/cup_dice_roll.ogg', 75, TRUE)

	var/list/hand = list()
	for(var/i in 1 to 5)
		hand += rand(1, 6)
	hands[roller] = hand
	rolls_used[roller] = 1
	selected_reroll[roller] = list()

	to_chat(roller, span_notice("Your first hand: [dice_poker_hand_to_text(hand)]"))
	game_bag.visible_message(span_notice("[roller] has rolled their first hand."))

	busy = FALSE

	var/mob/living/other = get_opponent(roller)
	if(!other)
		return

	if(rolls_used[other] < 1)
		current_player = other
		current_player_index = players.Find(other)
		can_take_action = TRUE
		to_chat(other, span_notice("Your turn: choose Roll Dice."))
		return

	phase = "betting"
	current_player = roller
	// round starter opens betting; if roller was second, switch to starter
	if(last_round_loser && (last_round_loser in players))
		current_player = last_round_loser
	else
		current_player = players[1]
	current_player_index = players.Find(current_player)
	can_take_action = TRUE

	game_bag.visible_message(span_notice("Both first rolls are in. Betting phase begins at bet [current_bet]."))
	to_chat(current_player, span_notice("Open betting: choose Bet / Respond."))

/datum/dice_poker_game/proc/do_betting_phase(mob/living/opener)
	if(opener != current_player)
		return
	var/mob/living/responder = get_opponent(opener)
	if(!responder)
		return

	busy = TRUE
	can_take_action = FALSE

	var/context = (phase == "initial_bet") ? "Initial Bet" : "Betting"
	var/mob/living/surrender_winner = perform_raise_chain(opener, responder, context)
	if(surrender_winner)
		var/mob/living/surrender_loser = (surrender_winner == opener) ? responder : opener
		busy = FALSE
		award_round_win(surrender_winner, surrender_loser, "surrender")
		return

	busy = FALSE

	if(phase == "initial_bet")
		phase = "initial_roll"
		current_player = round_starter
		current_player_index = players.Find(round_starter)
		if(current_player_index < 1)
			current_player = players[1]
			current_player_index = 1
		can_take_action = TRUE
		game_bag.visible_message(span_notice("Initial bet locked at [current_bet]. First roll phase begins."))
		to_chat(current_player, span_notice("Choose Roll Dice."))
		return

	phase = "reroll_select"
	current_player = round_starter
	current_player_index = players.Find(round_starter)
	if(current_player_index < 1)
		current_player = players[1]
		current_player_index = 1
	can_take_action = TRUE
	game_bag.visible_message(span_notice("Bet accepted at [current_bet]. Re-roll selection phase begins."))
	to_chat(current_player, span_notice("Choose Select Re-roll."))

/datum/dice_poker_game/proc/perform_raise_chain(mob/living/opener, mob/living/responder, context = "Betting")
	var/mob/living/acting = opener
	var/mob/living/other = responder
	var/first_prompt = TRUE

	while(TRUE)
		if(!acting || !other)
			return null

		var/cap = bet_caps[acting]
		var/list/options
		if(first_prompt)
			options = list("Keep Bet")
			if(cap >= 1)
				options += "Raise"
		else
			options = list("Accept", "Surrender")
			if(cap >= 1)
				options += "Raise"

		var/prompt = "[context]. Current bet: [current_bet]."
		var/choice = input(acting, prompt, "Dice Poker") as null|anything in options
		if(!choice)
			choice = first_prompt ? "Keep Bet" : "Accept"

		if(choice == "Surrender")
			return other

		if(choice == "Accept")
			return null

		if(choice == "Raise")
			var/raise_amt = prompt_raise_amount(acting, cap)
			if(raise_amt > 0)
				current_bet += raise_amt
				game_bag.visible_message(span_notice("[acting] raises by [raise_amt]. New bet: [current_bet]."))

		var/mob/living/tmp = acting
		acting = other
		other = tmp
		first_prompt = FALSE

/datum/dice_poker_game/proc/prompt_raise_amount(mob/living/actor, raise_cap)
	if(raise_cap < 1)
		return 0
	var/list/raise_choices = build_raise_choices(raise_cap)
	var/amt_txt = input(actor, "Raise by how much? (cap [raise_cap])", "Dice Poker") as null|anything in raise_choices
	if(!amt_txt)
		return 0
	return max(text2num("[amt_txt]"), 0)

/datum/dice_poker_game/proc/build_raise_choices(max_raise)
	var/list/out = list()
	var/cap = min(max_raise, 100)
	for(var/i in 1 to cap)
		out += "[i]"
	if(!out.len)
		out += "1"
	return out

/datum/dice_poker_game/proc/do_select_and_reroll(mob/living/actor)
	if(actor != current_player)
		return

	busy = TRUE
	can_take_action = FALSE

	var/list/hand = hands[actor]
	if(!hand || hand.len != 5)
		busy = FALSE
		return

	var/list/sel = list()
	while(TRUE)
		var/list/menu = list()
		var/list/choice_to_index = list()
		for(var/i in 1 to 5)
			var/mark = (i in sel) ? "[X]" : "[ ]"
			var/line = "[mark] Die [i]: [hand[i]]"
			menu += line
			choice_to_index[line] = i
		menu += "Done"

		var/choice = input(actor, "Select dice to re-roll. Toggle entries, then Done.", "Dice Poker") as null|anything in menu
		if(!choice || choice == "Done")
			break

		var/chosen_index = choice_to_index[choice]

		if(chosen_index)
			if(chosen_index in sel)
				sel -= chosen_index
			else
				sel += chosen_index

	selected_reroll[actor] = sel.Copy()
	reroll_mask[actor] = selection_to_mask(sel)

	if(sel.len)
		playsound(game_bag, 'sound/items/cup_dice_roll.ogg', 75, TRUE)
		for(var/i3 in sel)
			hand[i3] = rand(1, 6)
		game_bag.visible_message(span_notice("[actor] re-rolls [sel.len] die/dice."))
	else
		game_bag.visible_message(span_notice("[actor] keeps all dice (no re-roll)."))

	hands[actor] = hand
	rolls_used[actor] = max(rolls_used[actor], 2)
	to_chat(actor, span_notice("Your final hand: [dice_poker_hand_to_text(hand)]"))

	busy = FALSE

	var/mob/living/other = get_opponent(actor)
	if(!other)
		return

	if(rolls_used[other] < 2)
		current_player = other
		current_player_index = players.Find(other)
		can_take_action = TRUE
		to_chat(other, span_notice("Your turn: choose Select Re-roll."))
		return

	phase = "showdown"
	resolve_showdown_chain()

/datum/dice_poker_game/proc/resolve_showdown_chain()
	var/mob/living/A = players[1]
	var/mob/living/B = players[2]
	if(!A || !B)
		return

	while(TRUE)
		var/list/eval_a = dice_poker_eval(hands[A])
		var/list/eval_b = dice_poker_eval(hands[B])
		var/cmp = dice_poker_compare(eval_a, eval_b)

		game_bag.visible_message(span_notice("Reveal: [A] has [dice_poker_hand_to_text(hands[A])] ([eval_a["name"]]) | [B] has [dice_poker_hand_to_text(hands[B])] ([eval_b["name"]])."))

		if(cmp > 0)
			award_round_win(A, B, "better hand")
			return
		if(cmp < 0)
			award_round_win(B, A, "better hand")
			return

		game_bag.visible_message(span_warning("Perfect draw. Sudden Death triggers: extra betting + re-roll."))

		var/sd = sudden_death_cycle(A, B)
		if(sd == 1)
			award_round_win(A, B, "sudden death")
			return
		if(sd == -1)
			award_round_win(B, A, "sudden death")
			return
		// sd == 0 means tied again; loop continues

/datum/dice_poker_game/proc/sudden_death_cycle(mob/living/A, mob/living/B)
	var/mob/living/surrender_winner = perform_raise_chain(A, B, "Sudden Death")
	if(surrender_winner == A)
		return 1
	if(surrender_winner == B)
		return -1

	var/list/sel_a = choose_reroll_indexes(A)
	apply_reroll(A, sel_a)
	var/list/sel_b = choose_reroll_indexes(B)
	apply_reroll(B, sel_b)

	var/list/eval_a = dice_poker_eval(hands[A])
	var/list/eval_b = dice_poker_eval(hands[B])
	return dice_poker_compare(eval_a, eval_b)

/datum/dice_poker_game/proc/choose_reroll_indexes(mob/living/M)
	var/list/hand = hands[M]
	var/list/sel = list()
	while(TRUE)
		var/list/menu = list()
		var/list/choice_to_index = list()
		for(var/i in 1 to 5)
			var/mark = (i in sel) ? "[X]" : "[ ]"
			var/line = "[mark] Die [i]: [hand[i]]"
			menu += line
			choice_to_index[line] = i
		menu += "Done"
		var/choice = input(M, "Sudden Death re-roll selection.", "Dice Poker") as null|anything in menu
		if(!choice || choice == "Done")
			break
		var/j = choice_to_index[choice]
		if(j)
			if(j in sel)
				sel -= j
			else
				sel += j
	return sel

/datum/dice_poker_game/proc/selection_to_mask(list/sel)
	var/mask = 0
	if(!sel)
		return mask
	for(var/i in sel)
		if(i >= 1 && i <= 5)
			mask |= (1 << (i - 1))
	return mask

/datum/dice_poker_game/proc/apply_reroll(mob/living/M, list/indexes)
	var/list/hand = hands[M]
	if(!hand || hand.len != 5)
		return
	if(indexes && indexes.len)
		playsound(game_bag, 'sound/items/cup_dice_roll.ogg', 65, TRUE)
		for(var/i in indexes)
			hand[i] = rand(1, 6)
		hands[M] = hand
		to_chat(M, span_notice("Sudden Death hand: [dice_poker_hand_to_text(hand)]"))
		game_bag.visible_message(span_notice("[M] re-rolls [indexes.len] die/dice in Sudden Death."))
	else
		game_bag.visible_message(span_notice("[M] keeps all dice in Sudden Death."))

/datum/dice_poker_game/proc/award_round_win(mob/living/winner, mob/living/loser, reason)
	if(!winner)
		return

	round_wins[winner]++
	last_round_loser = loser

	game_bag.visible_message(span_notice("[winner] wins the round ([reason]) at bet [current_bet]! Score: [get_round_score_display()]."))

	if(round_wins[winner] >= 2)
		end_game_with_winner(winner, "best of three")
		return

	phase = "initial_roll"
	can_take_action = TRUE
	start_round()

/datum/dice_poker_game/proc/get_round_score_display()
	var/list/parts = list()
	for(var/mob/living/P in players)
		parts += "[P]: [round_wins[P]]"
	return jointext(parts, " | ")

/datum/dice_poker_game/proc/end_game_with_winner(mob/living/winner, reason)
	phase = "game_over"
	can_take_action = FALSE
	if(winner)
		game_bag.visible_message(span_notice("--- DICE POKER OVER --- [winner] wins by [reason]! Final score: [get_round_score_display()]."))
	else
		game_bag.visible_message(span_warning("--- DICE POKER OVER ---"))
	game_bag.active_game = null
	qdel(src)


/obj/item/storage/pill_bottle/dice/dice_poker
	name = "bag of dice poker dice"
	desc = "A bag used to play Dice Poker. Activate in hand (Z) to start or join a game."
	var/datum/dice_poker_game/active_game
	var/static/dice_poker_rules_text = {"<div style='padding:8px;font-family:Verdana,sans-serif;'>
	<h2 style='text-align:center;margin:0 0 6px 0;'>Dice Poker</h2>
<br>
<b>Objective:</b> Win 2 out of 3 rounds with the stronger hand.<br>
<br>
<b>Round Flow:</b><br>
1) First roll (5d6 each).<br>
2) Betting: raise / accept / re-raise / surrender.<br>
3) Select dice to re-roll once.<br>
4) Reveal and compare hands.<br>
<br>
<b>Ranking (low -> high):</b><br>
Nothing, Pair, Two Pairs, Three-of-a-Kind, Five High Straight,
Six High Straight, Full House, Four-of-a-Kind, Five-of-a-Kind.<br>
<br>
<b>Tie Rule:</b><br>
If hands are perfectly equal (including kickers), Sudden Death starts:
extra betting + re-roll, repeating until someone wins.<br>
<br>
<b>Note:</b> Betting caps scale with player luck/experience stats.<br>
</div>"}

/obj/item/storage/pill_bottle/dice/dice_poker/proc/show_rules(mob/living/user)
	if(!user)
		return
	user << browse(dice_poker_rules_text, "window=dice_poker_rules;size=720x520")

/obj/item/storage/pill_bottle/dice/dice_poker/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/dice/d6(src)

/obj/item/storage/pill_bottle/dice/dice_poker/attack_self(mob/living/user)
	if(active_game && active_game.joining && (user in active_game.players) && active_game.players.len >= 2)
		active_game.start_game()

	var/list/menu = list()
	var/can_roll = FALSE
	var/can_bet = FALSE
	var/can_reroll = FALSE

	if(active_game && !active_game.joining && user == active_game.current_player && active_game.can_take_action)
		if(active_game.phase == "initial_roll")
			can_roll = TRUE
		else if(active_game.phase == "initial_bet" || active_game.phase == "betting")
			can_bet = TRUE
		else if(active_game.phase == "reroll_select")
			can_reroll = TRUE

	if(!active_game)
		menu += "Start Game"
	else if(active_game.joining)
		if(!(user in active_game.players))
			menu += "Join Game"
	else
		if(can_roll)
			menu += "Roll Dice"
		if(can_bet)
			menu += "Bet / Respond"
		if(can_reroll)
			menu += "Select Re-roll"

	if(menu.len)
		menu += " "
	menu += "Rules"
	menu += "  "
	if(active_game && (user in active_game.players))
		menu += "Leave Game"
		menu += "   "
	menu += "End Game"

	var/choice = input(user, "Select an option.", "Dice Poker") as null|anything in menu
	if(!choice)
		return

	if(choice == "Rules")
		show_rules(user)
		return

	if(choice == "End Game")
		if(active_game)
			active_game.cancel_game(user)
		else
			to_chat(user, span_notice("No Dice Poker game is currently running."))
		return

	if(choice == "Leave Game")
		if(active_game)
			active_game.leave_game(user)
		else
			to_chat(user, span_notice("No Dice Poker game is currently running."))
		return

	if(choice == "Roll Dice")
		if(active_game)
			active_game.player_action(user, "Roll Dice")
		return

	if(choice == "Bet / Respond")
		if(active_game)
			active_game.player_action(user, "Bet / Respond")
		return

	if(choice == "Select Re-roll")
		if(active_game)
			active_game.player_action(user, "Select Re-roll")
		return

	if(choice == "Join Game")
		if(active_game && active_game.joining)
			active_game.try_join(user)
		return

	if(choice != "Start Game")
		return

	if(!active_game)
		var/count = input(user, "How many players?\n(2 players)", "Dice Poker") as null|anything in list(2)
		if(!count)
			return

		var/datum/dice_poker_game/new_game = new()
		new_game.game_bag = src
		new_game.max_players = count
		active_game = new_game
		new_game.try_join(user)
		src.visible_message(span_notice("[user] is starting Dice Poker! [count - 1] more player(s) needed. Activate (Z) the dice bag to join!"))
		return

	if(active_game.joining)
		active_game.try_join(user)
	else
		active_game.player_action(user, null)

#undef DICE_POKER_RANK_NOTHING
#undef DICE_POKER_RANK_PAIR
#undef DICE_POKER_RANK_TWO_PAIR
#undef DICE_POKER_RANK_TRIPS
#undef DICE_POKER_RANK_STRAIGHT_5
#undef DICE_POKER_RANK_STRAIGHT_6
#undef DICE_POKER_RANK_FULL_HOUSE
#undef DICE_POKER_RANK_FOUR_KIND
#undef DICE_POKER_RANK_FIVE_KIND
