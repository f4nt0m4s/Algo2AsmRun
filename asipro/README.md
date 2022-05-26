# asipro
Asm for SIPRO

SIPRO est un processeur 16 bits.
Le programmeur procède à la traduction de son fichier texte en suite d’opcodes en utilisant un programme appelé programme d’assemblage.


Flex fait l'analyse lexicale.
Bison fait l'analyse grammaticale pour générer le code assembleur.
Le code assembleur généré est compilé avec asipro et éxécuté avec sipro.


Pour utiliser asipro et sipro,

Compiler le dossier asm et emul avec le makefile présent dans ces dossiers.
Dans le dossier asm -> make
Dans le dossier emul -> make

Ensuite, il faut les ajouter à la variable PATH.
Ouvrir le fichier .bashrc (CTRL+H),
Récupère le chemin des dossiers asm et emul avec la commande pwd.
Ecrire dans le .bashrc :
export PATH="$PATH:/home/joo/Documents/Test/asm:/home/joo/Documents/Test/emul"

Utilisation de asipro :
```
asipro fichier.asm executable
sipro executable
```
