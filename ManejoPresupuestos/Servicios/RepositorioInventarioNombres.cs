using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioInventarioNombres
    {
        Task<IEnumerable<InventarioNombre>> ObtenerTodos();
        Task Crear(InventarioNombre nombre);
        Task<InventarioNombre?> ObtenerPorId(int id);
        Task Actualizar(InventarioNombre nombre);
        Task Borrar(int id);
    }

    public class RepositorioInventarioNombres : IRepositorioInventarioNombres
    {
        private readonly string connectionString;

        public RepositorioInventarioNombres(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<InventarioNombre>> ObtenerTodos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<InventarioNombre>(
                @"
                    SELECT * FROM TblInventariosNombres
                "
            );
        }

        public async Task Crear(InventarioNombre nombre)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblInventariosNombres (Nombre, Abreviatura)
                    VALUES (@Nombre, @Abreviatura);

                    SELECT SCOPE_IDENTITY();
                ",
                nombre
            );

            nombre.InventarioNombreId = id;
        }

        public async Task<InventarioNombre?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<InventarioNombre>(
                @"
                    SELECT * FROM TblInventariosNombres WHERE InventarioNombreId = @Id
                ",
                new { id }
            );
        }

        public async Task Actualizar(InventarioNombre nombre)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<InventarioNombre>(
                @"
                    UPDATE TblInventariosNombres SET Nombre = @Nombre, Abreviatura = @Abreviatura
                    WHERE InventarioNombreId = @InventarioNombreId;
                ",
                nombre
            );
        }

        public async Task Borrar(int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<InventarioNombre>(
                @"
                    DELETE TblInventariosNombres WHERE InventarioNombreId = @id;
                ",
                new { id }
            );
        }
    }
}
