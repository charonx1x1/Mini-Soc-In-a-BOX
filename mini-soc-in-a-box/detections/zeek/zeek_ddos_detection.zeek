# Script Zeek pour détecter les attaques DDOS SYN flood
# Détecte un grand nombre de connexions SYN sans réponse

@load base/frameworks/notice
@load base/utils/site

global syn_count_per_src: table[addr] of count &default=0;
global syn_count_per_dst: table[addr] of count &default=0;
global syn_threshold = 100;  # Seuil de détection

event new_connection(c: connection)
    {
    # Vérifier si c'est une connexion SYN (premier paquet)
    if ( c$orig$size > 0 && c$resp$size == 0 )
        {
        # Compter les SYN par source
        syn_count_per_src[c$id$orig_h] += 1;
        syn_count_per_dst[c$id$resp_h] += 1;
        
        # Détecter si seuil dépassé pour une source
        if ( syn_count_per_src[c$id$orig_h] > syn_threshold )
            {
            NOTICE([$note=DDOS::SYN_Flood,
                    $msg=fmt("Possible SYN flood attack from %s to %s (%d SYN packets)", 
                             c$id$orig_h, c$id$resp_h, syn_count_per_src[c$id$orig_h]),
                    $conn=c,
                    $identifier=cat(c$id$orig_h, c$id$resp_h)]);
            }
        }
    }

event connection_state_remove(c: connection)
    {
    # Nettoyer les compteurs quand la connexion se termine
    if ( c$id$orig_h in syn_count_per_src )
        {
        syn_count_per_src[c$id$orig_h] -= 1;
        if ( syn_count_per_src[c$id$orig_h] <= 0 )
            delete syn_count_per_src[c$id$orig_h];
        }
    }