using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioInventarioTipos
    {
        Task<IEnumerable<InventarioTipo>> ObtenerTodos();
        Task Crear(InventarioTipo tipo);
        Task<InventarioTipo?> ObtenerPorId(int id);
        Task Actualizar(InventarioTipo tipo);
        Task Borrar(int id);
    }

    public class RepositorioInventarioTipos : IRepositorioInventarioTipos
    {
        private readonly string connectionString;

        public RepositorioInventarioTipos(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<InventarioTipo>> ObtenerTodos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<InventarioTipo>(
                @"
                    SELECT * FROM TblInventariosTipos
                "
            );
        }

        public async Task Crear(InventarioTipo tipo)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblInventariosTipos (Nombre)
                    VALUES (@Nombre);

                    SELECT SCOPE_IDENTITY();
                ",
                tipo
            );

            tipo.InventarioTipoId = id;
        }

        public async Task<InventarioTipo?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<InventarioTipo>(
                @"
                    SELECT * FROM TblInventariosTipos WHERE InventarioTipoId = @Id
                ",
                new { id }
            );
        }

        public async Task Actualizar(InventarioTipo tipo)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<InventarioTipo>(
                @"
                    UPDATE TblInventariosTipos SET Nombre = @Nombre
                    WHERE InventarioTipoId = @InventarioTipoId;
                ",
                tipo
            );
        }

        public async Task Borrar(int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<InventarioTipo>(
                @"
                    DELETE TblInventariosTipos WHERE InventarioTipoId = @id;
                ",
                new { id }
            );
        }
    }
}
