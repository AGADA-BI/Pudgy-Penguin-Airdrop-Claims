--Query to get airdrop details

WITH supply_data AS (
    SELECT 
        88888888888 AS total_tokens, /* Total supply: 88,888,888,888 tokens */
        88888888888 * 0.259 AS tge_allocation /* Tokens available at TGE: 25.9% */
),
claimed_tokens AS (
    SELECT 
        SUM(amount / 1e6) AS claimed_tokens /* Adjusting for token decimals */
    FROM tokens_solana.transfers
    WHERE
        block_time >= TIMESTAMP '2024-12-17 13:00:00'
        AND token_mint_address = '2zMMhcVQEXDtdE6vsFS7S7D5oUodfJHE8vd1gnBouauv' /* Address for PENGU token */
        AND from_owner = '3HA76bpwHuST6Uo9BouJ4A5GpAiDuerr7QBenUqbXZAL' /* Specific sender address */
        AND to_owner IS NOT NULL
)
SELECT 
    sd.total_tokens AS "Total Token Supply",
    sd.tge_allocation AS "Allocation at TGE",
    ct.claimed_tokens AS "Claimed Tokens",
    (ct.claimed_tokens / sd.tge_allocation * 100) AS "Percentage Claimed",
    (sd.tge_allocation - ct.claimed_tokens) AS "Remaining Tokens",
    ((sd.tge_allocation - ct.claimed_tokens) / sd.tge_allocation * 100) AS "Percentage Unclaimed"
FROM supply_data sd
CROSS JOIN claimed_tokens ct;


--Query to get claim distribution

WITH data AS (
  SELECT
    to_owner AS claimers,
    DATE_TRUNC('HOUR', block_time) AS claim_hour,
    amount / 1e6 AS amount_claimed /* Adjusting decimal places for PENGU token */,
    CASE 
      WHEN amount / 1e6 < 1000 THEN '< 1k $PENGU'
      WHEN amount / 1e6 < 5000 THEN '1k-5k $PENGU'
      WHEN amount / 1e6 < 20000 THEN '5k-20k $PENGU'
      WHEN amount / 1e6 < 50000 THEN '20k-50k $PENGU'
      ELSE '> 50k $PENGU'
    END AS claim_bucket
  FROM tokens_solana.transfers
  WHERE
        block_time >= TIMESTAMP '2024-12-17 13:00:00'
        AND token_mint_address = '2zMMhcVQEXDtdE6vsFS7S7D5oUodfJHE8vd1gnBouauv' /* PENGU token address */
        AND from_owner = '3HA76bpwHuST6Uo9BouJ4A5GpAiDuerr7QBenUqbXZAL'
        AND to_owner != ''
)
SELECT
  claim_bucket AS "Claim Size Distribution",
  COUNT(*) AS "Number of Claims",
  ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS "% of Claims"
FROM data
GROUP BY claim_bucket
ORDER BY "Number of Claims" DESC;

--Query to get Top 10 claimers

WITH claimers AS (
    SELECT 
        to_owner as wallet_address,
        SUM(amount) / 1e6 as "PENGU claimed", /* Adjusting decimal places for PENGU token */
        MAX(block_time) as "claim time",
        CONCAT(
            '<a href=https://solscan.io/account/',
            to_owner,
            ' target=_blank">',
            to_owner,
            '</a>'
        ) as wallet_address_link
    FROM tokens_solana.transfers
    WHERE
        block_time >= TIMESTAMP '2024-12-17 13:00:00'
        AND token_mint_address = '2zMMhcVQEXDtdE6vsFS7S7D5oUodfJHE8vd1gnBouauv' /* PENGU token address */
        AND from_owner = '3HA76bpwHuST6Uo9BouJ4A5GpAiDuerr7QBenUqbXZAL'
        AND to_owner != ''
    GROUP BY 
        to_owner
    ORDER BY "PENGU claimed" DESC
    LIMIT 10
)
SELECT
    c.wallet_address,
    c.wallet_address_link,
    c."PENGU claimed",
    c."claim time"
FROM claimers c
ORDER BY c."PENGU claimed" DESC;
