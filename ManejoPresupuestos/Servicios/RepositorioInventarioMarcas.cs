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
        Task Actualizar(int usuarioId, InventarioMarca marca);
        Task Borrar(int usuarioId, int id);
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

        public async Task Actualizar(int usuarioId, InventarioMarca marca)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<InventarioMarca>(
                "procAlteraInventariosMarcas",
                new
                {
                    elementoAlterarId = marca.InventarioMarcaId,
                    nombre = marca.Nombre,
                    loginId = usuarioId,
                    actualizar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<InventarioMarca>(
                "procAlteraInventariosMarcas",
                new
                {
                    elementoAlterarId = id,
                    nombre = "Marca eliminada",
                    loginId = usuarioId,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
