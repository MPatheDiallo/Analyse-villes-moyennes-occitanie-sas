
/* ============================================================
   CC_BDSAS25 – Étude des villes moyennes (VM)
   Région étudiée : Occitanie
   Source : Base typo_vm associée à l’article
            Espaces et sociétés, 2024, n° 189-190, p. 49-74
   Jeu de données : doi:10.15454/GEC9XX (recherche.data.gouv.fr)
   Auteur : DIALLO&MAHAMAT
   Date : 29/01/2026
   ============================================================ */

options nodate nonumber validvarname=upcase;
ods graphics on;

/* Paramètres régionaux */
%let region   = Occitanie;
/* Départements Occitanie : 09 11 12 30 31 32 34 46 48 65 66 81 82 */
%let dep_list = "09","11","12","30","31","32","34","46","48","65","66","81","82";

/* Chemins (à adapter selon ton environnement SAS) */
libname projet   "/home/u64337494/Projet/Data";
libname resultas "/home/u64337494/Projet/Resultats";

/* ============================================================
   OUVERTURE DU PDF
   (tout ce qui suit ira dans ce fichier jusqu’à ods pdf close)
   ============================================================ */

ods pdf file="/home/u64337494/Projet/Resultats/CC_BDSAS25_VOTRENOMDEFAMILLE.pdf"
        style=journal;

/* ------------------------------------------------------------
   1. Contrôle rapide de la base source
   ------------------------------------------------------------ */

title1 "Contrôle de la base source projet.typo_vm";
title2 "Variables, effectifs et répartition de la variable VM";

proc datasets lib=projet nolist; quit;
proc datasets lib=resultas nolist; quit;

proc contents data=projet.typo_vm varnum;
run;

proc freq data=projet.typo_vm;
  tables vm / missing;
run;

proc sql;
  select count(*) as n_total format=comma10.
  from projet.typo_vm;
quit;
title;

data _null_;
  file print;
  put "------------------------------------------------------------";
  put "NOTE SYNTHÉTIQUE – BASE SOURCE (NATIONAL)";
  put "------------------------------------------------------------";
  put / "La table typo_vm est un fichier national au niveau des unités urbaines (UU),";
  put "contenant des indicateurs démographiques, socio-économiques et résidentiels.";
  put / "Elle comporte 2 409 observations et 30 variables.";
  put / "La variable vm isole 194 villes moyennes (8,05 %) au sein de 2 215 autres UU (91,95 %).";
  put "------------------------------------------------------------";
run;

/* ------------------------------------------------------------
   2. Sélection des UU de la région (Occitanie)
   ------------------------------------------------------------ */

title1 "Sélection des Unités urbaines en &region";
title2 "Filtrage par codes départements et exclusion des UU '00'";

proc sql;
  create table work.uu_region as
  select
    uu2020,
    vm,
    tuu2017,
    type,
    typo_5classes,
    p17_pop,
    tx_chom_2017,
    pmig0717,
    pnat0717,
    ptot0717,
    pct_logvac_2017,
    pct_logvac_0717,
    m15_p64_2017,
    thc_centre_gde_uu,
    disp_gi18,
    disp_q218_pct_fr,
    tx_cs_agri_2017, tx_cs_artisan_2017, tx_cs_cadre_2017,
    tx_cs_pr_int_2017, tx_cs_employe_2017, tx_cs_ouvrier_2017,
    tx_cs_agri_0717, tx_cs_artisan_0717, tx_cs_cadre_0717,
    tx_cs_pr_int_0717, tx_cs_employe_0717, tx_cs_ouvrier_0717
  from projet.typo_vm
  where substr(uu2020,1,2) in (&dep_list)
    and substr(uu2020,1,2) ne "00";
quit;

title3 "Effectifs d’Unités urbaines retenues en &region";
proc sql;
  select count(*) as n_uu_region format=comma10.
  from work.uu_region;
quit;

title3 "Répartition des UU par département (Occitanie)";
proc freq data=work.uu_region;
  tables uu2020 / nocum nopercent;
  format uu2020 $2.;
run;
title;

data _null_;
  file print;
  put "------------------------------------------------------------";
  put "NOTE SYNTHÉTIQUE – PÉRIMÈTRE RÉGIONAL (&region)";
  put "------------------------------------------------------------";
  put / "La sélection retient toutes les UU dont l’identifiant uu2020 commence par un code";
  put "département de l’Occitanie (09, 11, 12, 30, 31, 32, 34, 46, 48, 65, 66, 81, 82),";
  put "en excluant les identifiants commençant par '00' (UU multi-départements).";
  put "------------------------------------------------------------";
run;

/* ------------------------------------------------------------
   3. Sélection des villes moyennes (vm=1)
   ------------------------------------------------------------ */

title1 "Sélection des villes moyennes en &region";
title2 "Filtrage sur vm=1 (définition de la base de travail)";

proc sql;
  create table work.vm_region as
  select *
  from work.uu_region
  where vm = 1;
quit;

proc sql;
  select count(*) as n_vm_region format=comma10.
  from work.vm_region;
quit;
title;

data _null_;
  file print;
  put "------------------------------------------------------------";
  put "NOTE SYNTHÉTIQUE – POPULATION ÉTUDIÉE (VILLES MOYENNES)";
  put "------------------------------------------------------------";
  put / "L’analyse se concentre sur les villes moyennes d’Occitanie définies par vm=1.";
  put "------------------------------------------------------------";
run;

/* ------------------------------------------------------------
   4. Préparation : labels, formats
   ------------------------------------------------------------ */

proc format;
  value $tuu
    "1" = "UU < 20 000 hab."
    "2" = "UU 20 000–49 999 hab."
    "3" = "UU 50 000–99 999 hab."
    "4" = "UU 100 000–199 999 hab."
    "5" = "UU ≥ 200 000 hab."
    other = "Non renseigné";

  value $typeuu
    "1" = "UU isolée"
    "2" = "UU multipolaire"
    other = "Autre / non renseigné";
run;

data work.vm_region_prep;
  set work.vm_region;
  length dep $2;
  dep = substr(uu2020,1,2);
  format tuu2017 $tuu. type $typeuu.;
  /* labels comme dans ton code */
run;

/* Contrôle des valeurs manquantes */
title1 "Contrôle des valeurs manquantes – variables clés (VM &region)";
proc means data=work.vm_region_prep n nmiss;
  var p17_pop tx_chom_2017 pmig0717 pnat0717 ptot0717
      pct_logvac_2017 thc_centre_gde_uu disp_gi18 disp_q218_pct_fr;
run;
title;

/* ------------------------------------------------------------
   5. Descriptifs
   ------------------------------------------------------------ */

title1 "Descriptifs – Villes moyennes en &region";
title2 "Statistiques descriptives des indicateurs clés";

proc means data=work.vm_region_prep n mean median p25 p75 min max maxdec=2;
  var p17_pop tx_chom_2017 pmig0717 pnat0717 ptot0717
      pct_logvac_2017 thc_centre_gde_uu disp_gi18 disp_q218_pct_fr;
run;

title1 "Répartition par typologie (5 classes)";
title2 "Villes moyennes en &region";
proc freq data=work.vm_region_prep;
  tables typo_5classes / nocum;
run;

title1 "Typologie x taille UU (tuu2017)";
title2 "Villes moyennes en &region";
proc freq data=work.vm_region_prep;
  tables tuu2017*typo_5classes / norow nocol nopercent;
run;

/* ------------------------------------------------------------
   6. Graphiques
   ------------------------------------------------------------ */

title1 "Soldes naturel et migratoire – Villes moyennes (&region)";
proc sgplot data=work.vm_region_prep;
  refline 0 / axis=x;
  refline 0 / axis=y;
  scatter x=pnat0717 y=pmig0717 / group=typo_5classes;
  xaxis label="Solde naturel 2007–2017 (pnat0717)";
  yaxis label="Solde migratoire 2007–2017 (pmig0717)";
run;

title1 "Chômage 2017 par typologie – Villes moyennes (&region)";
proc sgplot data=work.vm_region_prep;
  vbox tx_chom_2017 / category=typo_5classes;
  yaxis label="Taux de chômage 2017";
  xaxis label="Typologie (5 classes)";
run;

title1 "Accessibilité et solde total – Villes moyennes (&region)";
proc sgplot data=work.vm_region_prep;
  scatter x=thc_centre_gde_uu y=ptot0717 / group=typo_5classes;
  xaxis label="Temps vers centre d’une grande UU (min)";
  yaxis label="Solde total 2007–2017 (ptot0717)";
run;

title1 "Vacance des logements 2017 par typologie – Villes moyennes (&region)";
proc sgplot data=work.vm_region_prep;
  vbox pct_logvac_2017 / category=typo_5classes;
  yaxis label="% de logements vacants (2017)";
  xaxis label="Typologie (5 classes)";
run;
title;

/* ------------------------------------------------------------
   7. Classements (Top 10)
   ------------------------------------------------------------ */

proc sql;
  create table work.vm_rank as
  select
    uu2020, dep, tuu2017, type, typo_5classes,
    p17_pop, tx_chom_2017, pct_logvac_2017,
    pmig0717, pnat0717, ptot0717, thc_centre_gde_uu
  from work.vm_region_prep;
quit;

/* Top 10 chômage */
proc sort data=work.vm_rank out=work.top_chom;
  by descending tx_chom_2017;
run;

title1 "Top 10 – Taux de chômage 2017 (VM &region)";
proc print data=work.top_chom(obs=10) noobs label;
  var uu2020 dep typo_5classes p17_pop tx_chom_2017 pct_logvac_2017 ptot0717;
run;

/* Top 10 vacance logements */
proc sort data=work.vm_rank out=work.top_vac;
  by descending pct_logvac_2017;
run;

title1 "Top 10 – Vacance des logements 2017 (VM &region)";
proc print data=work.top_vac(obs=10) noobs label;
  var uu2020 dep typo_5classes p17_pop pct_logvac_2017 tx_chom_2017 ptot0717;
run;
title;

/* ------------------------------------------------------------
   9. Corrélations + matrice nuage de points (comme dans le PDF)
   ------------------------------------------------------------ */
title "Corrélations entre indicateurs clés – Villes moyennes d’&region";
proc corr data=work.vm_region_prep pearson
          plots=matrix(histogram);
  var tx_chom_2017 pct_logvac_2017 pmig0717 pnat0717 ptot0717 thc_centre_gde_uu;
run;
title;

/* Corrélations ciblées – Fragilités urbaines (VAR vs WITH) */
title "Corrélations ciblées – Fragilités urbaines (VM &region)";
proc corr data=work.vm_region_prep pearson;
  var  tx_chom_2017 pct_logvac_2017;
  with pmig0717 pnat0717 ptot0717 thc_centre_gde_uu;
run;
title;

/* ============================================================
   FERMETURE DU PDF
   ============================================================ */

ods pdf close;

