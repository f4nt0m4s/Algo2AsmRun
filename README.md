# Projet de compilation

# Installation de l'émulateur assembleur SIPRO
1. ```/asipro/asm``` : ```make``` then ```pwd```
Dans le dossier /asipro/asm, éxécuter la commande make qui génère un éxécutable nommé asipro.
Récupèrer le chemin à partir de la commande pwd.
2. ```/asipro/emul``` : ```make``` then ```pwd```
Dans le dossier /asipro/emul, éxécuter la commande make qui génère un éxécutable nommé asipro.
Récupèrer le chemin à partir de la commande pwd.
3. Ajouts des chemins à la variable d'environnement $PATH
Ouvrez le fichier .bashrc (CTRL+H dans le répertoire utilisateur, ex : /home/username) 
et ajouter à la variable $PATH les chemins récupérés en les séparant par le caractère ```:``` deux points.
```
export PATH="$PATH:/home/username/Documents/GitHub/Algo2AsmRun/asipro/asm:/home/username/Documents/GitHub/Algo2AsmRun/asipro/emul"
```

# Utilisation des programmes du projet
## Commandes : 
Pour éxécuter ces commandes, vous devez être dans le répertoire racine du projet (```Algo2AsmRun```).
1. ```make algo2asm```
2. ```./algo2asm fichier.tex```
3. ```make run```
4. ```./run ’\SIPRO{nom_fonction}{argument1,argument2,...}’```
5. ```asipro fonction_nom_main nom_executable```
6. ```sipro nom_executable```

Dans le dossier tests se trouve des fichiers LaTeX permettant de tester :
Exemple avec un programme factorielle LaTeX:
1. ```make algo2asm```
2. ```./algo2asm tests/recursion/factorial.tex```
3. ```make run```
4. ```./run ’\SIPRO{factorial}{5}’```
5. ```asipro factorial_main executable```
6. ```sipro executable```

Ressources :
 - Read from bison with yyin and yyout : https://lists.gnu.org/archive/html/help-bison/2003-02/msg00054.html
