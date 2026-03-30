% Partie 3 du projet - prolog
% Par : Meagan Partington 300416906 et
% Anastasia Sadovskyy 300426037

% Tests pour petit fichier
 
% :- [rp].
 
% Tests pour grand fichier
 
:- [rp4000].
 
 
% Donner par le prof
 
test(1):-rankInProgram(403,nrs,R), write(R).
test(2):-leastPreferred(nrs,[403, 517, 226, 828],Rid,Rank),write(Rid),write(' '),write(Rank).
test(3):-Ms = [match(nrs, [517]), match(obg, []), match(mmi, [126]),match(hep, [226,574])], matched(226,P,Ms),write(P).
test(4):-M=[match(nrs, []), match(obg, []), match(mmi, [126]),match(hep, [226,574])], offer(517,M, NewM),write(NewM).
test(5):-M = [match(nrs, [517]), match(obg, []), match(mmi, [126]),match(hep, [226,574])], offer(403,M, NewM),write(NewM).
 
 
% Donner par le prof (predicat daffichage)
% Affiche une ligne de resultat pour un resident apparie
 
writeMatchInfo(ResidentID,ProgramID):-
    resident(ResidentID,name(FN,LN),_),
    program(ProgramID,TT,_,_),write(LN),write(','),
    write(FN),write(','),write(ResidentID),write(','),
    write(ProgramID),write(','),writeln(TT).
 
 
% Cache pour eviter de reparcourir les listes ROL a chaque fois
% Precalcule les rangs une seule fois au chargement
 
:- dynamic rank_cache/3.
 
% precompute_ranks(ProgramID, ROL, RangCourant)
% sauvegarde le rang de chaque resident dans le cache
% base case : liste vide
 
precompute_ranks(_, [], _).
 
% Si recursif, sauvegarder la tete et continuer
 
precompute_ranks(PID, [R|Rest], Rank) :-
    assertz(rank_cache(R, PID, Rank)),  % sauvegarder le rang du resident dans le cache
    Rank1 is Rank + 1,                  % incrementer le rang pour le prochain
    precompute_ranks(PID, Rest, Rank1). % continuer avec le reste du ROL
 
% Lance le precalcul pour tous les programmes au chargement
 
:- forall(program(PID, _, _, ROL), precompute_ranks(PID, ROL, 1)).
 
 
% calcule le rang dun resident dans le ROL dun programme
% utilise le cache au lieu de nth1 pour etre plus rapide
 
rankInProgram(ResidentID, ProgramID, Rank) :-
    rank_cache(ResidentID, ProgramID, Rank).  % consulter le cache
 
 
% identifie le resident le moins prefere dans une liste
% un seul resident dans la liste
 
leastPreferred(ProgramID, [R], R, Rank) :-
    rankInProgram(R, ProgramID, Rank).   % le rang du seul resident est son rang direct
 
% Si recursif, sa compare la tete avec le reste de la liste
 
leastPreferred(ProgramID, [R|Rest], LeastR, LeastRank) :-
    leastPreferred(ProgramID, Rest, TempR, TempRank),      % trouve le moins prefere dans le reste
    rankInProgram(R, ProgramID, RRank),     % obtenir le rang de la tete de la liste
 
    (RRank > TempRank ->    % si la tete a un rang plus eleve (AKA moins prefere)
    LeastR = R, LeastRank = RRank ;     % la tete devient le moins prefere
    LeastR = TempR, LeastRank = TempRank).  % sinon garder le moins prefere du reste
 
 
% Verifie si un resident est deja apparie a un programme dans lensemble courant
% le programme courant contient le resident
 
matched(ResidentID, ProgramID, [match(ProgramID, Residents)|_]) :-
    member(ResidentID, Residents), !.   % residnet trouve couper les autres choix
 
% Si recursif, chercher dans le reste de lensemble
 
matched(ResidentID, ProgramID, [_|Rest]) :-
    matched(ResidentID, ProgramID, Rest).   % continuer la recherche dans le reste
 
 
% Remplace la liste de residents dun programme dans lensemble dappariments
% on a trouver le programme on remplace sa liste de residents
 
updateMatch(ProgramID, NewRes, [match(ProgramID, _)|Rest], [match(ProgramID, NewRes)|Rest]) :- !.
 
% Si cest recursif garder le match courant et continuer le recherche
 
updateMatch(ProgramID, NewRes, [M|Rest], [M|NewRest]) :-
    updateMatch(ProgramID, NewRes, Rest, NewRest).  % continuer jusquau bon programme
 
 
% Essaie dapparier un resident a un programme specifique
% Si le programme a encore de la capaciter disponible...
 
tryMatch(ResidentID, ProgramID, Ms, NewMs) :-
    program(ProgramID, _, Cap, _),  % obtenir la capaciter du programme
    member(match(ProgramID, Matched), Ms),  % obtenir les residents deja apparies
    length(Matched, Num),   % compter combien sont deja apparies
    Num < Cap, !,   % verifier quil reste de la place (coupe si oui)
    rankInProgram(ResidentID, ProgramID, _),    % verfie que le resident est dans le ROL du programme
    updateMatch(ProgramID, [ResidentID|Matched], Ms, NewMs).    % ajouter le resident au programme
 
% Si le programme est plein mais le resident est preferer au moins preferer actuel
 
tryMatch(ResidentID, ProgramID, Ms, NewMs) :-
    member(match(ProgramID, Matched), Ms),  % obtenir les residents apparies
    rankInProgram(ResidentID, ProgramID, ResRank),  % rang du nouveau resident dans le ROL
    leastPreferred(ProgramID, Matched, LeastR, LeastRank),  % trouver le moins preferer actuel
    ResRank < LeastRank, !,    % le nouveau resident est plus preferer (couper)
    delete(Matched, LeastR, NewMatched),    % retirer le moins preferer de la liste
    updateMatch(ProgramID, [ResidentID|NewMatched], Ms, NewMs). % ajouter le nouveau resident a sa place
 
 
% essaie dapparier un resident avec chaque programme de sa liste de preferences
% si la liste de preferences est epuisee, retourner lensemble inchage
 
tryOffer(_, [], Ms, Ms).
 
% on essaye le premier programme, arreter si succes
 
tryOffer(ResidentID, [P|_], Ms, NewMs) :-
    tryMatch(ResidentID, P, Ms, NewMs), !.  % essayer le programme P, couper si reussi
 
% sinon essayer le prochain programme dans la liste de preferences
 
tryOffer(ResidentID, [_|Rest], Ms, NewMs) :-
    tryOffer(ResidentID, Rest, Ms, NewMs).      % passer au programme suivant
 
 
% essaye dassigner un programme a un resident
% le resident est deja apparie, retourner lensemble inchange
 
offer(ResidentID, Ms, Ms) :-
    matched(ResidentID, _, Ms), !.  % deja apparie, coupet et ne rien changer
 
% le resident nest pas apparie, essayer chaque programme de sa ROL
 
offer(ResidentID, Ms, NewMs) :-
    resident(ResidentID, _, Prefs),     % recuperer la liste de preferences du resident
    tryOffer(ResidentID, Prefs, Ms, NewMs).     % essayer chaque programme dans lordre de preference
 
 
% appelle offer pour chaque resident de la liste
% aucun resident a traiter
 
processAll([], Ms, Ms).
 
% Offrir un jumelage au premier resident, puis continuer
 
processAll([R|Rest], Ms, FinalMs) :-
    offer(R, Ms, TempMs),   % offrir un jumelage au resident R
    processAll(Rest, TempMs, FinalMs).  % continuer avec le reste des residents
 
 
% repete la boucle de jumelge jusqua ce que lensemble soit stable
 
iterate(Ms, FinalMs) :-
    findall(R, resident(R, _, _), Residents),   % obtenir la liste de tous les residents
    processAll(Residents, Ms, NewMs),   % effectuer un passage complet sur tous les residents
 
    (Ms == NewMs ->     % verifier si lensemble a changer apres ce passage
        FinalMs = NewMs ;       % stable : lensemble ne change plus alors on a terminer
        iterate(NewMs, FinalMs)     % pas stable : relancer un autre passage complet
    ).
 
 
% Affiche tous les residents apparies, groupe par programme
% Aucun programme a afficher
 
printMatched([]).
 
% Afficher les residents du programme courant, puis continuer
 
printMatched([match(P, Residents)|Rest]) :-
    printResidentsOfProgram(P, Residents),  % afficher tous les residents de ce programme
    printMatched(Rest).     % continuer avec le reste des programmes
 
 
% affiche chaque resident apparie a un programme donner
% aucun de residants dans ce programme
 
printResidentsOfProgram(_, []).
 
% afficher le resident courant, puis continuer
 
printResidentsOfProgram(P, [R|Rest]) :-
    writeMatchInfo(R, P),  % afficher les infos du resident R avec writeMatchInfo fourni
    printResidentsOfProgram(P, Rest).  % continuer avec le reste des resdients
 
 
% affiche tous les residents qui nont pas ete appries
 
printUnmatched(Ms) :-
    findall(R, (resident(R, _, _), \+ matched(R, _, Ms)), Unmatched),   % collecter tous les residents non-appariers
    printUnmatchedList(Unmatched).   % les afficher un par un
 
 
% affiche chaque resident non apparier dans le bon format
% aucun residents non appariers
 
printUnmatchedList([]).
 
printUnmatchedList([R|Rest]) :-
    resident(R, name(FN,LN), _),   % recuperer le nom du resident
    write(LN), write(','),    % afficher le nom de famille
    write(FN), write(','),    % afficher le prenom
    write(R), write(','),    % afficher lidentifiant du resident
    write('XXX'), write(','),   % aucun programme assigne
    writeln('NOT_MATCHED'),    % etiquette indiquant non-apparie
    printUnmatchedList(Rest).   % continuer avec le reste
 
 
% compte le nombre de residents non appariers
 
countUnmatched(Ms, Count) :-
    findall(R, (resident(R, _, _), \+ matched(R, _, Ms)), Unmatched),  % collecter les non-appariers
    length(Unmatched, Count).    % compter le nombre de residents non-appariers
 
 
% compte le total des postes non remplis dans tous les programmes.
% plus de programmes, 0 postes disponibles
 
countAvailablePositions([], 0).
 
% calculer les postes disponibles du programme courant, puis faire la somme
 
countAvailablePositions([match(P, Matched)|Rest], Total) :-
    program(P, _, Cap, _),  % obtenir la capaciter maximale du programme
    length(Matched, Filled),     % compter le nombre de postes deja remplies
    Available is Cap - Filled,  % calculer le nombre de postes encore disponibles
    countAvailablePositions(Rest, RestTotal),   % calculer le reste
    Total is Available + RestTotal.     % additionner pour obtenir le total
 
 
% ecrit une ligne de resultat pour un resident apparie dans un fichier
 
writeMatchInfoToFile(ResidentID, ProgramID, Stream) :-
    resident(ResidentID, name(FN,LN), _),          % recuperer le nom du resident
    program(ProgramID, TT, _, _),           % recuperer le nom du programme
    write(Stream, LN), write(Stream, ','),          % ecrire le nom de famille
    write(Stream, FN), write(Stream, ','),          % ecrire le prenom
    write(Stream, ResidentID), write(Stream, ','),       % ecrire lidentifiant
    write(Stream, ProgramID), write(Stream, ','),       % ecrire le programme
    writeln(Stream, TT).         % ecrire le nom complet du programme
 
 
% ecrit tous les residents apparies dans le fichier
% aucun programme a ecrire
 
printMatchedToFile([], _).
 
% ecrire les residents du programme courant, puis continuer
 
printMatchedToFile([match(P, Residents)|Rest], Stream) :-
    printResidentsToFile(P, Residents, Stream),  % ecrire les residents de ce programme
    printMatchedToFile(Rest, Stream).      % continuer avec le reste
 
 
% ecrit chaque resident apparie dans le fichier
% aucun resident dans ce programme
 
printResidentsToFile(_, [], _).
 
% ecrire le resident courant, puis continuer
 
printResidentsToFile(P, [R|Rest], Stream) :-
    writeMatchInfoToFile(R, P, Stream),      % ecrire les infos du resident
    printResidentsToFile(P, Rest, Stream).    % continuer avec le reste
 
 
% ecrit tous les residents non apparies dans le fichier
 
printUnmatchedToFile(Ms, Stream) :-
    findall(R, (resident(R, _, _), \+ matched(R, _, Ms)), Unmatched),  % collecter les non-apparies
    printUnmatchedListToFile(Unmatched, Stream).   % les ecrire dans le fichier
 
% aucun residents non appariers
 
printUnmatchedListToFile([], _).
 
% ecrire le resident courant, puis continuer
 
printUnmatchedListToFile([R|Rest], Stream) :-
    resident(R, name(FN,LN), _),             % recuperer le nom du resident
    write(Stream, LN), write(Stream, ','),        % ecrire le nom de famille
    write(Stream, FN), write(Stream, ','),        % ecrire le prenom
    write(Stream, R), write(Stream, ','),       % ecrire lidentifiant
    write(Stream, 'XXX'), write(Stream, ','),      % aucun programme assigne
    writeln(Stream, 'NOT_MATCHED'),          % etiquette non-apparie
    printUnmatchedListToFile(Rest, Stream).       % continuer avec le reste
 
 
% gale shapley - affiche dans la console
 
gale_shapley :-
    findall(match(P,[]), program(P,_,_,_), Ms0),  % initialiser lensemble vide (fourni dans lenonce)
    iterate(Ms0, FinalMs),     % executer lalgorithme jusqua stabilite
    printMatched(FinalMs),     % afficher tous les residents apparies dans la console
    printUnmatched(FinalMs),     % afficher tous les residents non apparies dans la console
    countUnmatched(FinalMs, U),    % compter les residents non apparies
    countAvailablePositions(FinalMs, A),     % compter les postes encore disponibles
    write('Number of unmatched residents: '), writeln(U),   % afficher dans la console
    write('Number of positions available: '), writeln(A),   % afficher dans la console
    open('output.txt', write, Stream),  % ouvrir le fichier output.txt
    printMatchedToFile(FinalMs, Stream),    % ecrire les residents apparies dans le fichier
    printUnmatchedToFile(FinalMs, Stream),  % ecrire les residents non apparies dans le fichier
    write(Stream, 'Number of unmatched residents: '), writeln(Stream, U),   % ecrire dans le fichier
    write(Stream, 'Number of positions available: '), writeln(Stream, A),   % ecrire dans le fichier
    close(Stream).  % fermer le fichier
 