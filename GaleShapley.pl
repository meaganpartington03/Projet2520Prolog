% Partie 3 du projet - prolog
% Par : Meagan Partington 300416906
% Anstasia Sardovskyy 300

% Donner par le prof

resident(574, name(salvatore,williams), [nrs,hep,mmi]).
resident(517, name(rosalie,frederick), [nrs,mmi]).
resident(126, name(indie,medrano), [mmi,nrs]).
resident(828, name(emma,tremmo), [obg,nrs]).
resident(403, name(aspyn,olson), [hep,nrs]).
resident(226, name(zev,jarvis), [mmi,hep,nrs]).
resident(913, name(camille,paquet), [obg,mmi,hep]).
resident(773, name(marie,clown), [obg]).
resident(616, name(laurent,robert), [obg,mmi,hep,nrs]).
resident(377, name(tom,tan), [mmi,obg]).
program(nrs, "Neurosurgery",4, [574,517,403,828,226,126]).
program(obg, "Obstetrics and Gynecology",3, [616,828,773,913]).
program(mmi, "Microbiology",1, [574,517,226,913,377,126]).
program(hep, "Hematological Pathology",2, [403,574,913,616,226]).


% Donner par le prof

test(1):-rankInProgram(403,nrs,R), write(R).
test(2):-leastPreferred(nrs,[403, 517, 226, 828],Rid,Rank),write(Rid),write(' '),write(Rank).
test(3):-Ms = [match(nrs, [517]), match(obg, []), match(mmi, [126]),match(hep, [226,574])], matched(226,P,Ms),write(P).
test(4):-M=[match(nrs, []), match(obg, []), match(mmi, [126]),match(hep, [226,574])], offer(517,M, NewM),write(NewM).
test(5):-M = [match(nrs, [517]), match(obg, []), match(mmi, [126]),match(hep, [226,574])], offer(403,M, NewM),write(NewM).
------------------

% Donner par le prof (predicat daffichage)
% Affiche une ligne de resultat pour un resident apparie

writeMatchInfo(ResidentID,ProgramID):-
    resident(ResidentID,name(FN,LN),_),
    program(ProgramID,TT,_,_),write(LN),write(','),
    write(FN),write(','),write(ResidentID),write(','),
    write(ProgramID),write(','),writeln(TT).
-------------------

% calcule le rang dun resident dans le ROL dun programme

rankInProgram(ResidentID, ProgramID, Rank) :-
    program(ProgramID, _, _, ROL), %recuperer la liste de preference du programme
    nth1(Rank, ROL, ResidentID). %trouver la position 1-base du resident dans cette liste
-------------------


% Identifie le resident le moins prefere dans une liste
%Base case, un seul resident dans la liste

leastPreferred(ProgramID, [R], R, Rank) :-
    rankInProgram(R, ProgramID, Rank). %le rang du seul resident est son rang direct


%Si recursif, sa compare la tete avec le reste de la liste

leastPreferred(ProgramID, [R|Rest], LeastR, LeastRank) :-
    leastPreferred(ProgramID, Rest, TempR, TempRank), %trouve le moins prefere dans le reste
    rankInProgram(R, ProgramID, RRank), %obtenir le rang de la tete de la liste

    (RRank > TempRank ->  %si la tete a un rang plus eleve (AKA moins prefere)
    LeastR = R, LeastRank = RRank ; %la tete devient le moins prefere
    LeastR = TempR, LeastRank = TempRank). %sinon garder le moins prefere du reste
------------------


%Verifie si un resident est deja apparie a un programme dans lensemble courant
%Base case le programme courant contient le resident

matched(ResidentID, ProgramID, [match(ProgramID, Residents)|_]) :-
    member(ResidentID, Residents), !. %residnet trouve couper les autres choix

%Si recursif, chercher dans le reste de lensemble

matched(ResidentID, ProgramID, [_|Rest]) :-
    matched(ResidentID, ProgramID, Rest). %continuer la recherche dans le reste
--------------


%Remplace la liste de residents dun programme dans lensemble dappariments
%Base case on a trouver le programme on remplace sa liste de residents

updateMatch(ProgramID, NewRes, [match(ProgramID, _)|Rest], [match(ProgramID, NewRes)|Rest]) :- !. 

%Si cest recursif garder le match courant et continuer le recherche

updateMatch(ProgramID, NewResm [M|Rest], [M|NewRest]) :-
    updateMatch(ProgramID, NewRes, Rest, NewRest). %continuer jusquau bon programme
----------------


%Essaie dapparier un resident a un programme specifique
%Si le programme a encore de la capaciter disponible...

tryMatch(ResidentID, ProgramID, Ms, NewMs) :-
    program(ProgramID, _, Cap, _), %obtenir la capaciter du programme
    member(match(ProgramID, Matched), Ms), %obtenir les residents deja apparies 
    
    length(Matched, Num), %compter combien sont deja apparies
    
    Num < Cap, !, %verifier quil reste de la place (coupe si oui)
    rankInProgram(ResidentID, ProgramID, _), %verfie que le resident est dans le ROL du programme
    
    updateMatch(ProgramID, [ResidentID|Matched], Ms, NewMs). %ajouter le resident au programme


%Si le programme est plein mais le resident est preferer au moins preferer actuel

tryMatch(ResidentID, ProgramID, Ms, NewMs) :-
    member(match(ProgramID, Matched), Ms), %obtenir les residents apparies
    rankInProgram(ResidentID, ProgramID, ResRank), %rang du nouveau resident dans le ROL
    leastPreferred(ProgramID, Matched, LeastR, LeastRank), %trouver le moins preferer actuel

    ResRank < LeastRank, !, %le nouveau resident est plus preferer (couper)
    delete(Matched, LeastR, NewMatched), %retirer le moins preferer de la liste
    updateMatch(ProgramID, [ResidentID|NewMatched], Ms, NewMs). %ajouter le nouveau resident a sa place
    



