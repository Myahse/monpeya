package com.monpeya.server.config;

import java.util.HashMap;
import java.util.Map;

import javax.sql.DataSource;

import jakarta.persistence.EntityManagerFactory;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.jdbc.autoconfigure.DataSourceProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

@Configuration
@EnableTransactionManagement
@EnableJpaRepositories(basePackages = "com.djogana.ticketing.api.repository",
        entityManagerFactoryRef = "billetterieEntityManagerFactory",
        transactionManagerRef = "billetterieTransactionManager")
public class BilletterieJpaConfig {

    @Bean
    @ConfigurationProperties("spring.datasource.billetterie")
    public DataSourceProperties billetterieDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean
    public DataSource billetterieDataSource() {
        return billetterieDataSourceProperties().initializeDataSourceBuilder().build();
    }

    @Bean
    public LocalContainerEntityManagerFactoryBean billetterieEntityManagerFactory(
            @Qualifier("billetterieDataSource") DataSource dataSource) {
        LocalContainerEntityManagerFactoryBean factory = new LocalContainerEntityManagerFactoryBean();
        factory.setDataSource(dataSource);
        factory.setPackagesToScan("com.djogana.ticketing.api.entity");
        factory.setPersistenceUnitName("billetterie");
        factory.setJpaVendorAdapter(new HibernateJpaVendorAdapter());
        factory.setJpaPropertyMap(hibernateProperties());
        return factory;
    }

    @Bean
    public PlatformTransactionManager billetterieTransactionManager(
            @Qualifier("billetterieEntityManagerFactory") EntityManagerFactory entityManagerFactory) {
        return new JpaTransactionManager(entityManagerFactory);
    }

    private Map<String, Object> hibernateProperties() {
        Map<String, Object> props = new HashMap<>();
        props.put("hibernate.hbm2ddl.auto", "none");
        props.put("hibernate.dialect", "org.hibernate.dialect.OracleDialect");
        props.put("hibernate.format_sql", "true");
        return props;
    }
}
