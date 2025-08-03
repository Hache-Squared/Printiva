using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioInventarioMarcas
    {
        Task<IEnumerable<InventarioMarca>> ObtenerTodos();
        Task Crear(InventarioMarca marca);
        Task<InventarioMarca?> ObtenerPorId(int id);
        Task Actualizar(InventarioMarca marca);
        Task Borrar(int id);
    }

    public class RepositorioInventarioMarcas : IRepositorioInventarioMarcas
    {
        private readonly string connectionString;

        public RepositorioInventarioMarcas(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<InventarioMarca>> ObtenerTodos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<InventarioMarca>(
                @"
                    SELECT * FROM TblInventariosMarcas
                "
            );
        }

        public async Task Crear(InventarioMarca marca)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblInventariosMarcas (Nombre)
                    VALUES (@Nombre);

                    SELECT SCOPE_IDENTITY();
                ",
                marca
            );

            marca.InventarioMarcaId = id;
        }

        public async Task<InventarioMarca?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<InventarioMarca>(
                @"
                    SELECT * FROM TblInventariosMarcas WHERE InventarioMarcaId = @Id
                ",
                new { id }
            );
        }

        public async Task Actualizar(InventarioMarca marca)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<InventarioMarca>(
                @"
                    UPDATE TblInventariosMarcas SET Nombre = @Nombre
                    WHERE InventarioMarcaId = @InventarioMarcaId;
                ",
                marca
            );
        }

        public async Task Borrar(int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<InventarioMarca>(
                @"
                    DELETE TblInventariosMarcas WHERE InventarioMarcaId = @id;
                ",
                new { id }
            );
        }
    }
}
