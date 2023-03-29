DROP FUNCTION IF EXISTS offersGrowthCheck(smallint, varchar, bigint, float8, float8, real, real);
CREATE FUNCTION offersGrowthCheck
    (calc_method smallint, fst_n_lst_date_m1 varchar DEFAULT '0',
    transact_cnt_m2 bigint DEFAULT 0, k_check_incs float8, churn_idx float8,
    trans_share_max real, marge_share_avl real)
    RETURNS table (Customer_ID bigint, Required_Check_Measure real,
                    Group_Name varchar, Offer_Discount_Depth real)
    LANGUAGE plpgsql AS
    $$
    BEGIN
        IF (calc_method = 1) THEN
            RETURN QUERY (
                SELECT * FROM cards
            );
        ELSEIF (calc_method = 2) THEN
            RETURN QUERY (
                SELECT * FROM cards
            );
        ELSE
            RAISE EXCEPTION
                'Average check calculation method must be 1 or 2 (1 - per period, 2 - per quantity)';
        END IF;
    END;
    $$;

DROP FUNCTION IF EXISTS avgCheckM1(character varying);
CREATE FUNCTION avgCheckM1 (fst_n_lst_date_m1 varchar)
    RETURNS TABLE (Customer_ID bigint, Avg_check real)
    LANGUAGE plpgsql AS
    $$
    DECLARE
        lower_date date := split_part(fst_n_lst_date_m1, ' ', 1)::date;
        upper_date date := split_part(fst_n_lst_date_m1, ' ', 2)::date;
    BEGIN
        IF (lower_date < getKeyDates(1)) THEN
            lower_date = getKeyDates(1);
        ELSEIF (upper_date > getKeyDates(2)) THEN
            upper_date = getKeyDates(2);
        ELSEIF (lower_date >= upper_date) THEN
            RAISE EXCEPTION
                'last date of the specified period must be later than the first one';
        END IF;
        RETURN QUERY
            WITH pre_query AS (
                SELECT cards.customer_id AS Customer_ID, t.transaction_summ AS trans_summ
                FROM cards
                JOIN transactions t on cards.customer_card_id = t.customer_card_id
                WHERE t.transaction_datetime BETWEEN lower_date and upper_date)
            SELECT pq.Customer_ID, avg(trans_summ)::real AS Avg_check
            FROM pre_query pq
            GROUP BY pq.Customer_ID
            ORDER BY 1;
    END;
    $$;

DROP FUNCTION IF EXISTS avgCheckM2(bigint);
CREATE FUNCTION avgCheckM2 (transact_num bigint)
    RETURNS TABLE (Customer_ID bigint, Avg_check real)
    LANGUAGE plpgsql AS
    $$
    BEGIN
        RETURN QUERY
        WITH pre_query AS (
            SELECT customer_card_id, transaction_summ
            FROM transactions
            ORDER BY transaction_datetime DESC LIMIT transact_num)
        SELECT c.Customer_ID, avg(transaction_summ)::real AS Avg_check
        FROM pre_query pq
        JOIN cards c ON c.customer_card_id = pq.customer_card_id
        GROUP BY c.Customer_ID
        ORDER BY 1;
    END;
    $$;

DROP FUNCTION IF EXISTS getKeyDates(integer);
CREATE FUNCTION getKeyDates(key integer)
    RETURNS SETOF date
    LANGUAGE plpgsql AS
    $$
    BEGIN
        IF (key = 1) THEN
            RETURN QUERY
            SELECT transaction_datetime::date
            FROM transactions
            ORDER BY 1 LIMIT 1;
        ELSEIF (key = 2) THEN
            RETURN QUERY
            SELECT transaction_datetime::date
            FROM transactions
            ORDER BY 1 DESC LIMIT 1;
        END IF;
    END;
    $$;