

package com.djogana.ticketing.api.contracts;

import javax.crypto.NoSuchPaddingException;
import java.security.NoSuchAlgorithmException;
import java.text.ParseException;
import java.util.Locale;

/**
 * IBasic Business
 * 
 * @author Geo
 *
 */
public interface IBasicBusiness<T, K> {

	/**
	 * create Object by using T as object.
	 * 
	 * @param T
	 * @return K
	 * @throws ParseException 
	 * 
	 */
	public abstract K create(T request, Locale locale) throws ParseException;

	/**
	 * update Object by using T as object.
	 * 
	 * @param T
	 * @return K
	 * @throws ParseException 
	 * 
	 */
	public abstract K update(T request, Locale locale) throws ParseException, NoSuchPaddingException, NoSuchAlgorithmException;

	/**
	 * delete Object by using T as object.
	 * 
	 * @param T
	 * @return K
	 * 
	 */
	public abstract K delete(T request, Locale locale);
	
	/**
	 * delete Object by using T as object.
	 * 
	 * @param T
	 * @return K
	 * @throws ParseException 
	 * 
	 */
	public abstract K forceDelete(T request, Locale locale) throws ParseException;


	/**
	 * get a List of Object by using T as criteria object.
	 * 
	 * @param T
	 * @return K
	 * @throws Exception 
	 * 
	 */
	public abstract K getByCriteria(T request, Locale locale) throws Exception;
}
