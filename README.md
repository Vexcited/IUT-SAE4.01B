# SAE4.01B - Mise en place d'une zone démilitarisée

Ce projet est une extension de la SAE 3.01B qui vise à améliorer la sécurité de l'infrastructure réseau du CHU en séparant le routage et en mettant en place un filtrage plus strict.

## Modifications principales par rapport à la SAE 3.01B

1. **Séparation du routage en trois priorités** :
   - Routeur haute priorité (`r_high`) : pour l'infrastructure critique et de haute priorité
   - Routeur priorité moyenne (`r_mid`) : pour l'accès éducatif/universitaire
   - Routeur basse priorité (`r_low`) : pour l'accès non-prioritaire

2. **Classification des sous-réseaux** :
   - Haute priorité : serveur S, personnel soignant, comptabilité, chercheurs, enseignants-chercheurs, DSI
   - Priorité moyenne : étudiants, enseignants
   - Basse priorité : patients, visiteurs

3. **Accès à distance sécurisé** :
   - Configuration SSH pour permettre l'accès à distance sécurisé depuis le réseau DSI
   - Filtrage basé sur le principe du moindre privilège

## Infrastructure

L'infrastructure réseau conserve les sous-réseaux suivants de la SAE 3.01B :
- Réseau patients : sousplage de classe C
- Réseau visiteurs : sousplage en /26
- Réseau enseignants, chercheurs et enseignants-chercheurs : sousplage en /22
- Réseau étudiants : sousplage en /22
- Réseau comptabilité : sousplage en /24
- Réseau personnel soignant : sousplage en /22
- Réseau serveur S : sousplage en /28 contenant les machines S et DNS
- Réseau DSI : sousplage en /24

## Règles de pare-feu

### Routeur haute priorité (r_high)
- Accepte le trafic critique (BDD, S, applications métier)
- Permet l'accès SSH pour l'administration à distance
- Autorise les connexions DNS, HTTP/HTTPS, et protocoles email
- Accepte les connexions pour l'application de gestion des patients (port 1224)
- Autorise SFTP pour les chercheurs vers la BDD

### Routeur priorité moyenne (r_mid)
- Accepte le trafic éducatif (étudiants, enseignants)
- Autorise l'accès au site web public et intranet
- Permet les connexions email pour les utilisateurs éducatifs
- Limite l'accès aux applications métier

### Routeur basse priorité (r_low)
- Accepte uniquement le trafic non-critique (patients, visiteurs)
- Autorise l'accès au site web public uniquement
- Limite l'accès aux ressources internes

## Tests automatisés

Pour tester la configuration, exécutez sur n'importe quelle machine :

```bash
chmod +x /shared/testing/test.sh && /shared/testing/test.sh
```

## Comparaison avec la SAE 3.01B

Par rapport à la configuration de la SAE 3.01B :
- Amélioration de la résilience avec 3 routeurs distincts pour Internet au lieu d'un seul
- Mise en place d'une gestion des priorités selon la criticité des services
- Renforcement de la sécurité par l'accès SSH distant sécurisé
- Tests automatisés plus complets pour valider la configuration
